#include <jniapi.h>
#include <JavaString.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <libunwind.h>
#include <string>
#include <assert.h>
#include <inttypes.h>
#include <errno.h>
#include <time.h>

namespace JNI {

class JNI
{
	JavaVM* javaVM;
	jclass classLoaderClass;
	jobject classLoaderInstance;
	jmethodID findClassMethod;
	jclass versionCodeClass;
	jfieldID versionCodeField;
	char eventsPath[PATH_MAX];

	JNI () {
		memset (eventsPath, 0, sizeof (eventsPath));

		javaVM = nullptr;
		classLoaderClass = nullptr;
		classLoaderInstance = nullptr;
		findClassMethod = nullptr;
		versionCodeClass = nullptr;
		versionCodeField = nullptr;
	}

	~JNI () {
		javaVM = nullptr;

		ReleaseGlobalReferencedObject (classLoaderClass);
		classLoaderClass = nullptr;

		ReleaseGlobalReferencedObject (classLoaderInstance);
		classLoaderInstance = nullptr;

		ReleaseGlobalReferencedObject (versionCodeClass);
		versionCodeClass = nullptr;

		findClassMethod = nullptr;
		versionCodeField = nullptr;
	}

public:
	static JNI& Get () {
		static JNI jni;
		return jni;
	}

	JavaVM* GetJavaVM () const {
		return javaVM;
	}

	JNIEnv* GetEnv () const {
		CHECKMSG (javaVM != nullptr, "Java virtual machine reference cannot be nullptr!");

		JNIEnv* env = nullptr;
		int status = javaVM->GetEnv ((void**) &env, JNI_VERSION_1_6);
		switch (status) {
			case JNI_EDETACHED: {
				//Attach current thread to environment
		    	int statusAttach = javaVM->AttachCurrentThread (&env, nullptr);
		        CHECKARG (statusAttach == 0, "Cannot attach current thread to environment! status: %d", statusAttach);
		        break;
	    	}
		    case JNI_OK:
			    break;
		    default:
		    case JNI_EVERSION: {
		        CHECKMSG (nullptr, "Version not supported!");
		        break;
		    }
		}

		CHECKMSG (env != nullptr, "env cannot be nullptr!");
		return env;
	}

	int GetSDKVersion () const {
		return GetEnv ()->GetStaticIntField (versionCodeClass, versionCodeField);
	}

	void SetEventsPath (const char* path) {
		if (path == nullptr) {
			memset (eventsPath, 0, sizeof (eventsPath));
		} else {
			strcpy (eventsPath, path);
		}
	}

	const char* GetEventsPath () const {
		return eventsPath;
	}

	void Init (JavaVM* vm, const char* loaderClassName) {
		javaVM = vm;

		JNIEnv* env = GetEnv ();

		AutoLocalRef<jclass> appSpecificClass (env->FindClass (loaderClassName), "JNI::Init () - appSpecificClass");
		CHECKMSG (appSpecificClass != nullptr, (std::string ("cannot find java class: '") + loaderClassName + std::string ("'")).c_str ());

		AutoLocalRef<jclass> classClass (env->FindClass ("java/lang/Class"), "JNI::Init () - classClass");
		CHECKMSG (classClass != nullptr, "cannot find java class: 'java/lang/Class'");

		AutoLocalRef<jclass> classLoaderClassLocalRef (env->FindClass ("java/lang/ClassLoader"), "JNI::Init () - classLoaderClassLocalRef");
		CHECKMSG (classLoaderClassLocalRef != nullptr, "cannot find java class: 'java/lang/ClassLoader'");

		classLoaderClass = GlobalReferenceObject (classLoaderClassLocalRef.get (), "cannot reference java class: 'java/lang/ClassLoader'");

		jmethodID getClassLoaderMethod = env->GetMethodID (classClass, "getClassLoader", "()Ljava/lang/ClassLoader;");
		CHECKMSG (getClassLoaderMethod != nullptr, "cannot find java method: 'ClassLoader Class.getClassLoader ()'");

		AutoLocalRef<jobject> classLoaderInstanceLocalRef (env->CallObjectMethod (appSpecificClass, getClassLoaderMethod), "JNI::Init () - classLoaderInstanceLocalRef");
		CHECKMSG (classLoaderInstanceLocalRef != nullptr, "cannot find java instance of class: 'java/lang/ClassLoader'");

		classLoaderInstance = GlobalReferenceObject (classLoaderInstanceLocalRef.get (), "cannot reference java instance of class: 'java/lang/ClassLoader'");

		findClassMethod = env->GetMethodID (classLoaderClass, "findClass", "(Ljava/lang/String;)Ljava/lang/Class;");
		CHECKMSG (findClassMethod != nullptr, "cannot find java method: 'Class ClassLoader.findClass (String name)'");

		AutoLocalRef<jclass> classBuildVersion (env->FindClass ("android/os/Build$VERSION"), "JNI::Init () - classBuildVersion");
		CHECKMSG (classBuildVersion != nullptr, "cannot find java class: 'android/os/Build$VERSION'");

		versionCodeClass = GlobalReferenceObject (classBuildVersion.get (), "cannot reference java class: 'android/os/Build$VERSION'");

		versionCodeField = env->GetStaticFieldID (versionCodeClass, "SDK_INT", "I");
		CHECKMSG (versionCodeField != nullptr, "cannot find java field: 'static int Build.VERSION.SDK_INT'");
	}

	jobject GetClassLoaderInstance () const {
		return classLoaderInstance;
	}

	jmethodID GetFindClassMethod () const {
		return findClassMethod;
	}
};

JavaVM* GetJavaVM ()
{
	JNI& jni = JNI::Get ();
	return jni.GetJavaVM ();
}

JNIEnv* GetEnv ()
{
	JNI& jni = JNI::Get ();
	return jni.GetEnv ();
}

int GetSDKVersion () {
	JNI& jni = JNI::Get ();
	return jni.GetSDKVersion ();
}

namespace Signal {
	std::string getStackTrace ();
}

std::string GetStackTrace () {
	return Signal::getStackTrace ();
}

void SetEventsPath (const char* path) {
	JNI::Get ().SetEventsPath (path);
}

const char* GetEventsPath () {
	return JNI::Get ().GetEventsPath ();
}

jclass FindClass (const char* signature)
{
	JNI& jni = JNI::Get ();
	JNIEnv* env = jni.GetEnv ();

	jclass result = env->FindClass (signature);
	if (env->ExceptionCheck () || result == nullptr) { //If environment not knows this class, then try to find in Java
		//Ignore Java exception, if occured...
		env->ExceptionClear ();

		//Find class with java on ClassLoader
		jstring str = env->NewStringUTF (signature);
		result = reinterpret_cast<jclass> (env->CallObjectMethod (jni.GetClassLoaderInstance (), jni.GetFindClassMethod (), str));
		env->DeleteLocalRef (str);
	}

	CHECKARG (!env->ExceptionCheck (), "Couldn't find class: %s, Java exception occured!", signature);
	CHECKARG (result != nullptr, "Couldn't find class: %s", signature);

	return result;
}

jmethodID GetMethod (jclass clazz, const char* method, const char* signature) {
	JNIEnv* env = GetEnv ();
	jmethodID result = env->GetMethodID (clazz, method, signature);
	CHECKARG (!env->ExceptionCheck (), "Couldn't find method: %s, signature: %s, Java exception occured!", method, signature);
	CHECKARG (result != nullptr, "Couldn't find method: %s, signature: %s", method, signature);
	return result;
}

jmethodID GetStaticMethod (jclass clazz, const char* method, const char* signature) {
	JNIEnv* env = GetEnv ();
	jmethodID result = env->GetStaticMethodID (clazz, method, signature);
	CHECKARG (!env->ExceptionCheck (), "Couldn't find static method: %s, signature: %s, Java exception occured!", method, signature);
	CHECKARG (result != nullptr, "Couldn't find static method: %s, signature: %s", method, signature);
	return result;
}

jfieldID GetField (jclass clazz, const char* field, const char* signature) {
	JNIEnv* env = GetEnv ();
	jfieldID result = env->GetFieldID (clazz, field, signature);
	CHECKARG (!env->ExceptionCheck (), "Couldn't find field: %s, signature: %s, Java exception occured!", field, signature);
	CHECKARG (result != nullptr, "Couldn't find field: %s, signature: %s", field, signature);
	return result;
}

jfieldID GetStaticField (jclass clazz, const char* field, const char* signature) {
	JNIEnv* env = GetEnv ();
	jfieldID result = env->GetStaticFieldID (clazz, field, signature);
	CHECKARG (!env->ExceptionCheck (), "Couldn't find static field: %s, signature: %s, Java exception occured!", field, signature);
	CHECKARG (result != nullptr, "Couldn't find static field: %s, signature: %s", field, signature);
	return result;
}

void EnsureLocalCapacity (int neededRefCountCapacity) {
	CHECKMSG (neededRefCountCapacity > 0, "The needed local frame ref count capacity must be greater than 0!");

	JNIEnv* env = GetEnv ();
	jint res = env->EnsureLocalCapacity (neededRefCountCapacity);

	CHECKARG (!env->ExceptionCheck (), "Couldn't ensure local frame capacity for references! neededRefCount: %d", neededRefCountCapacity);
	CHECKARG (res == 0, "Couldn't ensure local frame capacity for references! neededRefCount: %d", neededRefCountCapacity);
}

void PushLocalFrame (int neededRefCount)
{
	CHECKMSG (neededRefCount > 0, "The needed local frame ref count must be greater than 0!");

	JNIEnv* env = GetEnv ();
	jint res = env->PushLocalFrame (neededRefCount);

	CHECKARG (!env->ExceptionCheck (), "Couldn't create local frame for references! neededRefCount: %d", neededRefCount);
	CHECKARG (res == 0, "Couldn't create local frame for references! neededRefCount: %d", neededRefCount);
}

void PopLocalFrame ()
{
	JNIEnv* env = GetEnv ();
	env->PopLocalFrame (nullptr);
	CHECKARG (!env->ExceptionCheck (), "Couldn't release local frame for references!");
}

jobject GlobalReferenceObject (jobject obj, const char* errorMessage)
{
	CHECKMSG (obj != nullptr, "Couldn't global reference object with null pointer!");

	//Create global reference
	JNIEnv* env = GetEnv ();
	jobject result = reinterpret_cast<jobject> (env->NewGlobalRef (obj));
	if (errorMessage == nullptr) {
		CHECKMSG (!env->ExceptionCheck (), "Couldn't global reference object! Java exception occured!");
		CHECKMSG (result != nullptr, "Couldn't global reference object!");
	} else {
		CHECKARG (!env->ExceptionCheck (), "Couldn't global reference object! Java exception occured! msg: %s", errorMessage);
		CHECKARG (result != nullptr, "Couldn't global reference object! msg: %s", errorMessage);
	}

	// LOGI ("GlobalReferenceObject () - src obj: 0x%08x, globalRef result: 0x%08x, refType: %d, msg: %s", (int)obj, (int)result, obj == nullptr ? -1 : (int) GetEnv ()->GetObjectRefType (obj), errorMessage);

	return result;
}

bool IsGlobalReference (jobject obj)
{
	if (obj != nullptr)
		return GetEnv ()->GetObjectRefType (obj) == JNIGlobalRefType;
	return false;
}

void ReleaseGlobalReferencedObject (jobject obj, const char* errorMessage)
{
	// LOGI ("ReleaseGlobalReferencedObject () - obj: 0x%08x, refType: %d, msg: %s", (int)obj, obj == nullptr ? -1 : (int) GetEnv ()->GetObjectRefType (obj), errorMessage);

	if (obj != nullptr) {
		JNIEnv* env = GetEnv ();

		jthrowable exc = env->ExceptionOccurred ();
		if (exc != nullptr) {
			env->ExceptionClear ();
		}

		jobjectRefType refType = env->GetObjectRefType (obj);
		if (refType == JNIGlobalRefType) {
			env->DeleteGlobalRef (obj);
		} else {
			if (errorMessage == nullptr) {
				CHECKARG (!env->ExceptionCheck (), "Couldn't release referenced object! Reference error! Unknown or unhandled reference type... refType: %d", (int)refType);
			} else {
				CHECKARG (!env->ExceptionCheck (), "Couldn't release referenced object! Reference error! Unknown or unhandled reference type... refType: %d, msg: %s", (int)refType, errorMessage);
			}
		}

		if (errorMessage == nullptr) {
			CHECKMSG (!env->ExceptionCheck (), "Couldn't release referenced object! Java exception occured!");
		} else {
			CHECKARG (!env->ExceptionCheck (), "Couldn't release referenced object! Java exception occured! msg: %s", errorMessage);
		}

		if (exc != nullptr) {
			env->Throw (exc);
		}
	}
}

jobject LocalReferenceObject (jobject obj, const char* errorMessage)
{
	CHECKMSG (obj != nullptr, "Couldn't local reference object with null pointer!");

	//Create local reference
	JNIEnv* env = GetEnv ();
	jobject result = reinterpret_cast<jobject> (env->NewLocalRef (obj));
	if (errorMessage == nullptr) {
		CHECKMSG (!env->ExceptionCheck (), "Couldn't local reference object! Java exception occured!");
		CHECKMSG (result != nullptr, "Couldn't local reference object!");
	} else {
		CHECKARG (!env->ExceptionCheck (), "Couldn't local reference object! Java exception occured! msg: %s", errorMessage);
		CHECKARG (result != nullptr, "Couldn't local reference object! msg: %s", errorMessage);
	}

	// LOGI ("LocalReferenceObject () - src obj: 0x%08x, localRef result: 0x%08x, refType: %d, msg: %s", (int)obj, (int)result, obj == nullptr ? -1 : (int) GetEnv ()->GetObjectRefType (obj), errorMessage);

	return result;
}

bool IsLocalReference (jobject obj)
{
	if (obj != nullptr)
		return GetEnv ()->GetObjectRefType (obj) == JNILocalRefType;
	return false;
}

void ReleaseLocalReferencedObject (jobject obj, const char* errorMessage)
{
	// LOGI ("ReleaseLocalReferencedObject () - obj: 0x%08x, refType: %d, msg: %s", (int)obj, obj == nullptr ? -1 : (int) GetEnv ()->GetObjectRefType (obj), errorMessage);

	if (obj != nullptr) {
		JNIEnv* env = GetEnv ();

		jobjectRefType refType = env->GetObjectRefType (obj);
		if (refType == JNILocalRefType)
			env->DeleteLocalRef (obj);
		else {
			if (errorMessage == nullptr) {
				CHECKARG (!env->ExceptionCheck (), "Couldn't release local referenced object! Reference error! Unknown or unhandled reference type... refType: %d", (int)refType);
			} else {
				CHECKARG (!env->ExceptionCheck (), "Couldn't release local referenced object! Reference error! Unknown or unhandled reference type... refType: %d, msg: %s", (int)refType, errorMessage);
			}
		}

		if (errorMessage == nullptr) {
			CHECKMSG (!env->ExceptionCheck (), "Couldn't release referenced object! Java exception occured!");
		} else {
			CHECKARG (!env->ExceptionCheck (), "Couldn't release referenced object! Java exception occured! msg: %s", errorMessage);
		}
	}
}

void DumpReferenceTables ()
{
	JNIEnv* env = GetEnv ();
	AutoLocalRef<jclass> vm_class (FindClass ("dalvik/system/VMDebug"), "Java class of dalvik/system/VMDebug");
	jmethodID method = env->GetStaticMethodID (vm_class, "dumpReferenceTables", "()V");
	env->CallStaticVoidMethod (vm_class, method);
}

const char* JMETHOD {"jmethod"};
const char* JFIELD {"jfield"};
const char* JSTATICMETHOD {"jstaticmethod"};
const char* JSTATICFIELD {"jstaticfield"};

void Caller::Init () {
	if (IsInited ()) {
		return;
	}

	for (const auto it : GetClassesToRegister ()) {
		AutoLocalRef <jclass> clazz (FindClass (it.second));
		_classes.emplace (it.first, GlobalReferenceObject (clazz.get (), it.second));
	}
	GetClassesToRegister ().clear ();

	const char** lastClassID = 0;
	jclass lastClazz = 0;
	for (const auto it : GetCallablesToRegister ()) {
		const char** classID = std::get<0> (it.second);
		const char* type = std::get<1> (it.second);
		const char* name = std::get<2> (it.second);
		const char* signature = std::get<3> (it.second);

		jclass clazz = lastClazz;
		if (classID != lastClassID) {
			clazz = _classes.find (classID)->second;
			lastClazz = clazz;
			lastClassID = classID;
		}

		if (type == JMETHOD) {
			_methods.emplace (it.first, GetMethod (clazz, name, signature));
		} else if (type == JFIELD) {
			_fields.emplace (it.first, GetField (clazz, name, signature));
		} else if (type == JSTATICMETHOD) {
			_methods.emplace (it.first, GetStaticMethod (clazz, name, signature));
		} else if (type == JSTATICFIELD) {
			_fields.emplace (it.first, GetStaticField (clazz, name, signature));
		}
	}
	GetCallablesToRegister ().clear ();
}

void Caller::Release () {
	if (!IsInited ()) {
		return;
	}

	_methods.clear ();
	_fields.clear ();
	_static_methods.clear ();
	_static_fields.clear ();

	for (const auto it : _classes) {
		ReleaseGlobalReferencedObject (it.second);
	}
	_classes.clear ();
}

void ThrowException (const char* clazz, const char* msg) {
	jclass exceptionClass = FindClass (clazz);
	CHECKARG (exceptionClass != nullptr, "Unable to find exception class %s", clazz);

	JNIEnv* env = GetEnv ();
	int status = env->ThrowNew (exceptionClass, msg);
	CHECKARG (status == JNI_OK, "Failed throwing '%s' '%s'", clazz, msg);
}

std::string StrError (int errnum) {

#if defined(__USE_GNU) && __ANDROID_API__ >= 23
	
	char buf[1024];
	char* ret = strerror_r (errnum, buf, sizeof (buf));
	return std::string (ret);
	
#else // POSIX
	
	char buf[1024];
	int ret = strerror_r (errnum, buf, sizeof (buf));
	
	if (ret == 0)
		return std::string (buf);
	
	snprintf (buf, sizeof (buf), "errnum %d", errnum);
	return std::string (buf);
	
#endif // __USE_GNU
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// C Signal handler override
//////////////////////////////////////////////////////////////////////////////////////////////////
namespace Signal {

enum eType
{
	eType_BUS,
	eType_SEGV,
	eType_SYS,
	eType_FPE,
	eType_ILL,
	eType_HUP,

	eType_Count
};

struct sigaction g_signalHandlers[eType_Count][2]; ///< 0 -> new signal handlers, 1 -> old signal handlers.
bool g_signalThrowed[eType_Count];
int g_signalSDKVersion = 0; ///< Signal handlers are not working on Android 5.0 or above. (SDK_INT == 21 for Android 5.0)

const int g_signalStackTraceBufferLength = 1024*1024;
char g_signalStackTraceBuffer[g_signalStackTraceBufferLength];

void buildSignalContext (void* signalReserved, unw_context_t* uc) {
//platform specific voodoo to build a context for libunwind
#if defined(__arm__)
	typedef struct unw_tdep_context {
		unsigned long regs[16];
	} unw_tdep_context_t;

	//cast/extract the necessary structures
	ucontext_t* context = (ucontext_t*) signalReserved;
	unw_tdep_context_t* unw_ctx = (unw_tdep_context_t*) uc;
	sigcontext* sig_ctx = &context->uc_mcontext;

	//we need to store all the general purpose registers so that libunwind can resolve
	//    the stack correctly, so we read them from the sigcontext into the unw_context
	unw_ctx->regs[UNW_ARM_R0] = sig_ctx->arm_r0;
	unw_ctx->regs[UNW_ARM_R1] = sig_ctx->arm_r1;
	unw_ctx->regs[UNW_ARM_R2] = sig_ctx->arm_r2;
	unw_ctx->regs[UNW_ARM_R3] = sig_ctx->arm_r3;
	unw_ctx->regs[UNW_ARM_R4] = sig_ctx->arm_r4;
	unw_ctx->regs[UNW_ARM_R5] = sig_ctx->arm_r5;
	unw_ctx->regs[UNW_ARM_R6] = sig_ctx->arm_r6;
	unw_ctx->regs[UNW_ARM_R7] = sig_ctx->arm_r7;
	unw_ctx->regs[UNW_ARM_R8] = sig_ctx->arm_r8;
	unw_ctx->regs[UNW_ARM_R9] = sig_ctx->arm_r9;
	unw_ctx->regs[UNW_ARM_R10] = sig_ctx->arm_r10;
	unw_ctx->regs[UNW_ARM_R11] = sig_ctx->arm_fp;
	unw_ctx->regs[UNW_ARM_R12] = sig_ctx->arm_ip;
	unw_ctx->regs[UNW_ARM_R13] = sig_ctx->arm_sp;
	unw_ctx->regs[UNW_ARM_R14] = sig_ctx->arm_lr;
	unw_ctx->regs[UNW_ARM_R15] = sig_ctx->arm_pc;
#elif defined(__i386__)
	//on x86 libunwind just uses the ucontext_t directly
	ucontext_t* context = (ucontext_t*)signalReserved;
	uc = ((unw_context_t*)context);
#else
	//We don't have platform specific voodoo for whatever we were built for, so
	//just call libunwind and hope it can jump out of the signal stack on it's own
	unw_getcontext (uc);
#endif
}

void addPointerToStackTrace (void* ptr) {
	strcat (g_signalStackTraceBuffer, "0x");

	char hex[] = "0123456789abcdef";
	size_t len = strlen (g_signalStackTraceBuffer);
	uint64_t val = (uint64_t)ptr;
	for (int i = 0;i < sizeof (ptr);++i) {
		int shift = (sizeof (ptr) - i - 1) * 8;

		uint8_t ch = (uint8_t) ((val >> shift) & 0xFF);
		g_signalStackTraceBuffer[len + (i*2) + 0] = hex[(ch & 0xF0) >> 4];
		g_signalStackTraceBuffer[len + (i*2) + 1] = hex[ch & 0x0F];
	}
}

void dumpStackTrace (void* signalReserved) {
	//Clear stack trace buffer
	memset (g_signalStackTraceBuffer, 0, sizeof (g_signalStackTraceBuffer));

	//Dump stack trace
	int ignoreStepCount;
	char funcName[1024];
	unw_cursor_t cursor;
	unw_context_t uc;
	unw_word_t ip, sp, offp;

	if (signalReserved != nullptr) {
		buildSignalContext (signalReserved, &uc);
		ignoreStepCount = 1;
	} else {
		unw_getcontext (&uc);
		ignoreStepCount = 3;
	}

	/*int result =*/ unw_init_local (&cursor, &uc);
//	if(!result){
//		if(result == -UNW_EBADREG){
//			//register needed wasn't accessible
//		}
//	}

	//intentionally skip the first frame, since that's this function
	int step = 0;
	bool first = true;
	while (unw_step (&cursor) > 0) {
		++step;
		if (step < ignoreStepCount) {
			continue;
		}

		if (unw_is_signal_frame (&cursor)) {
			strcat (g_signalStackTraceBuffer, "signal frame: ");
		}
		unw_get_reg (&cursor, UNW_REG_IP, &ip);
		unw_get_reg (&cursor, UNW_REG_SP, &sp);
		unw_get_proc_name (&cursor, funcName, 1024, &offp);

		//Log stack trace
		if (!first) {
			strcat (g_signalStackTraceBuffer, "|");
		}
		first = false;

		strcat (g_signalStackTraceBuffer, "pc=");
		addPointerToStackTrace ((void*)ip);

		strcat (g_signalStackTraceBuffer, " sp=");
		addPointerToStackTrace ((void*)sp);

		strcat (g_signalStackTraceBuffer, " : ");
		strcat (g_signalStackTraceBuffer, funcName);

		strcat (g_signalStackTraceBuffer, " + ");
		addPointerToStackTrace ((void*)offp);
	}
}

std::string getStackTrace () {
	dumpStackTrace (nullptr);
	return std::string (g_signalStackTraceBuffer);
}

void throwFromSignal (void* context, const char* signalName, int signalCode, int signalErrno, void* signalAddress)
{
	char pars[128];
	snprintf (pars, 128, "code:%d,errno:%d,addr:0x%016llx", signalCode, signalErrno, (unsigned long long) signalAddress);

	if (g_signalSDKVersion < 21) { // Below Android 5.0
		JNIEnv* env = GetEnv ();
		AutoLocalRef<jclass> vm_class (FindClass ("com/zapp/acw/bll/NetLogger"), "Java class of com/zapp/acw/bll/NetLogger");
		jmethodID method = env->GetStaticMethodID (vm_class, "throwFromSignal", "(Ljava/lang/String;Ljava/lang/String;)V");
		env->CallStaticVoidMethod (vm_class, method, JavaString (signalName).get (), JavaString (std::string (pars)).get ());
	} else { //Android 5.0 or above
		char crashPath[PATH_MAX];
		strlcpy (crashPath, GetEventsPath (), sizeof (crashPath));

		mode_t chrashFileMode = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP;

		struct stat eventPathStat;
		int res = stat (crashPath, &eventPathStat);
		if (res == 0 && (eventPathStat.st_mode & S_IFDIR)) {
			//Crash directory already exists...
		}
//		} else if (errno == ENOENT) {
//			res = mkdir (crashPath, 0770); //Make sure event directory exists...
//		}

		if (res == 0) {
			char dumpName[64];
			struct timespec tm;
			clock_gettime (CLOCK_REALTIME, &tm);

			uint64_t nanosec = tm.tv_sec * 1000000000ull + tm.tv_nsec;
			sprintf (dumpName, "/%" PRIu64 ".nativecrash", nanosec);
			strlcat (crashPath, dumpName, sizeof (crashPath));

			int fd = open (crashPath, O_WRONLY | O_CREAT | O_TRUNC, chrashFileMode);
			if (fd >= 0) {
				int32_t sigNameLen = strlen (signalName);
				write (fd, &sigNameLen, sizeof (sigNameLen));
				write (fd, signalName, sigNameLen);

				int32_t parsLen = strlen (pars);
				write (fd, &parsLen, sizeof (parsLen));
				write (fd, pars, parsLen);

				dumpStackTrace (context);
				int32_t stackTraceLen = strlen (g_signalStackTraceBuffer);
				write (fd, &stackTraceLen, sizeof (stackTraceLen));
				write (fd, g_signalStackTraceBuffer, stackTraceLen);

				close (fd);
			}
		}
	}
}

void signalHandler (int signalNumber, siginfo_t* sigInfo, void* context)
{
	// LOGI ("C Signal occured! signalNumber: %d, sigInfo: %08x, context: %08x", signalNumber, (uint32_t)sigInfo, (uint32_t)context);

	eType type = eType_Count;
	const char* name = "UNKNOWN";

	switch (signalNumber) {
		case SIGBUS: type = eType_BUS; name = "SIGBUS"; break;
		case SIGSEGV: type = eType_SEGV; name = "SIGSEGV"; break;
		case SIGSYS: type = eType_SYS; name = "SIGSYS"; break;
		case SIGFPE: type = eType_FPE; name = "SIGFPE"; break;
		case SIGILL: type = eType_ILL; name = "SIGILL"; break;
		case SIGHUP: type = eType_HUP; name = "SIGHUP"; break;
		default:
			break;
	}

	if (type != eType_Count) {
		if (g_signalThrowed[type]) {
			g_signalThrowed[type] = false;
			g_signalHandlers[type][1].sa_sigaction (signalNumber, sigInfo, context);
		} else {
			if (sigInfo != nullptr) {
				throwFromSignal (context, name, sigInfo->si_code, sigInfo->si_errno, sigInfo->si_addr);
			} else {
				throwFromSignal (context, name, 0, 0, nullptr);
			}
			g_signalThrowed[type] = true;
		}
	}
}

void addSignalHandler (int signalNumber, eType type)
{
	g_signalThrowed[type] = false;

	memset (&g_signalHandlers[type][0], 0, sizeof(g_signalHandlers[type][0]));
	sigemptyset (&g_signalHandlers[type][0].sa_mask);
	g_signalHandlers[type][0].sa_sigaction = signalHandler;
    g_signalHandlers[type][0].sa_flags = SA_SIGINFO;

    sigaction (signalNumber, &g_signalHandlers[type][0], &g_signalHandlers[type][1]);
}

void initSignalHandlers ()
{
	g_signalSDKVersion = GetSDKVersion ();

	addSignalHandler (SIGBUS, eType_BUS);
	addSignalHandler (SIGSEGV, eType_SEGV);
	addSignalHandler (SIGSYS, eType_SYS);
	addSignalHandler (SIGFPE, eType_FPE);
	addSignalHandler (SIGILL, eType_ILL);
	addSignalHandler (SIGHUP, eType_HUP);
}

void releaseSignalHandlers ()
{
	sigaction (SIGBUS, &g_signalHandlers[eType_BUS][1], nullptr);
	sigaction (SIGSEGV, &g_signalHandlers[eType_SEGV][1], nullptr);
	sigaction (SIGSYS, &g_signalHandlers[eType_SYS][1], nullptr);
	sigaction (SIGFPE, &g_signalHandlers[eType_FPE][1], nullptr);
	sigaction (SIGILL, &g_signalHandlers[eType_ILL][1], nullptr);
	sigaction (SIGHUP, &g_signalHandlers[eType_HUP][1], nullptr);
}

} //namespace Signal

int APILoad (JavaVM* vm, const char* loaderClassName) {
	//Init JNI layer
	JNI& jni = JNI::Get ();
	jni.Init (vm, loaderClassName);

	//Init signal handler
	Signal::initSignalHandlers ();

	//Init app specific stuffs
	//...

    return JNI_VERSION_1_6;
}

void APIUnload (JavaVM* vm) {
	//Destroy app specific stuffs
	//...

	//Destroy signal handler
	Signal::releaseSignalHandlers ();
}

} //namespace JNI
