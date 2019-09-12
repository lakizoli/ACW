//
// Created by Laki Zoltán on 2019-09-10.
//

#include <JavaString.h>
#include <JavaContainers.h>
#include "GeneratorInfo.hpp"

namespace {
//Java class signature
	JNI::jClassID jCardClass {"com/zapp/acw/bll/Card"};
	JNI::jClassID jFieldClass {"com/zapp/acw/bll/Field"};
	JNI::jClassID jGeneratorInfoClass {"com/zapp/acw/bll/GeneratorInfo"};

//Java method and field signatures
	JNI::jCallableID jCardInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jCardIDField {JNI::JFIELD, "cardID", "J"};
	JNI::jCallableID jNoteIDField {JNI::JFIELD, "noteID", "J"};
	JNI::jCallableID jModelIDField {JNI::JFIELD, "modelID", "J"};
	JNI::jCallableID jFieldValuesField {JNI::JFIELD, "fieldValues", "Ljava/util/ArrayList;"};
	JNI::jCallableID jSolutionFieldValueField {JNI::JFIELD, "solutionFieldValue", "Ljava/lang/String;"};

	JNI::jCallableID jFieldInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jIdxField {JNI::JFIELD, "idx", "J"};
	JNI::jCallableID jNameField {JNI::JFIELD, "name", "Ljava/lang/String;"};

	JNI::jCallableID jGeneratorInfoInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jDecksField {JNI::JFIELD, "decks", "Ljava/util/ArrayList;"};
	JNI::jCallableID jCardsField {JNI::JFIELD, "cards", "Ljava/util/ArrayList;"};
	JNI::jCallableID jFieldsField {JNI::JFIELD, "fields", "Ljava/util/ArrayList;"};
	JNI::jCallableID jUsedWordsField {JNI::JFIELD, "usedWords", "Ljava/util/ArrayList;"};
	JNI::jCallableID jCrosswordNameField {JNI::JFIELD, "crosswordName", "Ljava/lang/String;"};
	JNI::jCallableID jWidthField {JNI::JFIELD, "width", "I"};
	JNI::jCallableID jHeightField {JNI::JFIELD, "height", "I"};
	JNI::jCallableID jQuestionFieldIndexField {JNI::JFIELD, "questionFieldIndex", "I"};
	JNI::jCallableID jSolutionFieldIndexField {JNI::JFIELD, "solutionFieldIndex", "I"};
	JNI::jCallableID jSplitArrayField {JNI::JFIELD, "splitArray", "Ljava/util/ArrayList;"};
	JNI::jCallableID jSolutionsFixesField {JNI::JFIELD, "solutionsFixes", "Ljava/util/HashMap;"};

//Register jni calls
	JNI::CallRegister<jCardClass, jCardInitMethod, jCardIDField, jNoteIDField, jModelIDField, jFieldValuesField, jSolutionFieldValueField> JNI_CardClass;
	JNI::CallRegister<jFieldClass, jFieldInitMethod, jIdxField, jNameField> JNI_FieldClass;
	JNI::CallRegister<jGeneratorInfoClass, jGeneratorInfoInitMethod, jDecksField, jCardsField, jFieldsField, jUsedWordsField, jCrosswordNameField, jWidthField,
		jHeightField, jQuestionFieldIndexField, jSolutionFieldIndexField, jSplitArrayField, jSolutionsFixesField> JNI_GeneratorInfoClass;
}

Card::Card () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jCardClass), JNI::JavaMethod (jCardInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void Card::SetCardID (uint64_t cardID) {
	JNI::GetEnv ()->SetLongField (mObject, JNI::JavaField (jCardIDField), (jlong) cardID);
}

void Card::SetNoteID (uint64_t noteID) {
	JNI::GetEnv ()->SetLongField (mObject, JNI::JavaField (jNoteIDField), (jlong) noteID);
}

void Card::SetModelID (uint64_t modelID) {
	JNI::GetEnv ()->SetLongField (mObject, JNI::JavaField (jModelIDField), (jlong) modelID);
}

void Card::AddFieldValue (const std::string& fieldValue) {
	JavaArrayList<JavaString> fieldValues = JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jFieldValuesField));
	fieldValues.add (JavaString (fieldValue));
}

void Card::SetSolutionFieldValue (const std::string& solutionFieldValue) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jSolutionFieldValueField), JavaString (solutionFieldValue).get ());
}

JavaArrayList<JavaString> Card::GetFieldValues () const {
	return JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jFieldValuesField));
}

Field::Field () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jFieldClass), JNI::JavaMethod (jFieldInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void Field::SetIdx (uint32_t idx) {
	JNI::GetEnv ()->SetLongField (mObject, JNI::JavaField (jIdxField), (jlong) idx);
}

void Field::SetName (const std::string& name) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jNameField), JavaString (name).get ());
}

GeneratorInfo::GeneratorInfo () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jGeneratorInfoClass), JNI::JavaMethod (jGeneratorInfoInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void GeneratorInfo::AddDeck (const Deck& deck) {
	JavaArrayList<Deck> decks = JNI::GetObjectField<JavaArrayList<Deck>> (mObject, JNI::JavaField (jDecksField));
	decks.add (deck);
}

void GeneratorInfo::AddCard (const Card& card) {
	JavaArrayList<Card> cards = JNI::GetObjectField<JavaArrayList<Card>> (mObject, JNI::JavaField (jCardsField));
	cards.add (card);
}

void GeneratorInfo::AddField (const Field& field) {
	JavaArrayList<Field> fields = JNI::GetObjectField<JavaArrayList<Field>> (mObject, JNI::JavaField (jFieldsField));
	fields.add (field);
}

void GeneratorInfo::AddUsedWord (const JavaString& usedWord) {
	JavaArrayList<JavaString> usedWords = JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jUsedWordsField));
	usedWords.add (usedWord);
}

void GeneratorInfo::ClearUsedWords () {
	JavaArrayList<JavaString> usedWords = JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jUsedWordsField));
	usedWords.clear ();
}

void GeneratorInfo::SetCrosswordName (const std::string& crosswordName) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jCrosswordNameField), JavaString (crosswordName).get ());
}

void GeneratorInfo::SetWidth (int width) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jWidthField), width);
}

void GeneratorInfo::SetHeight (int height) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jHeightField), height);
}

void GeneratorInfo::SetQuestionFieldIndex (int questionFieldIndex) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jQuestionFieldIndexField), questionFieldIndex);
}

void GeneratorInfo::SetSolutionFieldIndex (int solutionFieldIndex) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jSolutionFieldIndexField), solutionFieldIndex);
}

JavaArrayList<Deck> GeneratorInfo::GetDecks () const {
	return JNI::GetObjectField<JavaArrayList<Deck>> (mObject, JNI::JavaField (jDecksField));
}

JavaArrayList<Card> GeneratorInfo::GetCards () const {
	return JNI::GetObjectField<JavaArrayList<Card>> (mObject, JNI::JavaField (jCardsField));
}

JavaArrayList<JavaString> GeneratorInfo::GetUsedWords () const {
	return JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jUsedWordsField));
}

std::string GeneratorInfo::GetCrosswordName () const {
	return JNI::GetObjectField<JavaString> (mObject, JNI::JavaField (jCrosswordNameField)).getString ();
}

int GeneratorInfo::GetWidth () const {
	return JNI::GetEnv ()->GetIntField (mObject, JNI::JavaField (jWidthField));
}

int GeneratorInfo::GetHeight () const {
	return JNI::GetEnv ()->GetIntField (mObject, JNI::JavaField (jHeightField));
}

JavaArrayList<JavaString> GeneratorInfo::GetSplitArray () const {
	return JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jSplitArrayField));
}

JavaArrayList<JavaString> GeneratorInfo::GetSolutionFixes () const {
	return JNI::GetObjectField<JavaArrayList<JavaString>> (mObject, JNI::JavaField (jSolutionsFixesField));
}

int GeneratorInfo::GetQuestionFieldIndex () const {
	return JNI::GetEnv ()->GetIntField (mObject, JNI::JavaField (jQuestionFieldIndexField));
}

int GeneratorInfo::GetSolutionFieldIndex () const {
	return JNI::GetEnv ()->GetIntField (mObject, JNI::JavaField (jSolutionFieldIndexField));
}
