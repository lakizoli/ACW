//
// Created by Laki Zoltán on 2019-09-05.
//

#include "Package.hpp"
#include <JavaString.h>

namespace {
//Java class signature
	JNI::jClassID jGameStateClass {"com/zapp/acw/bll/GameState"};
	JNI::jClassID jDeckClass {"com/zapp/acw/bll/Deck"};
	JNI::jClassID jPackageClass {"com/zapp/acw/bll/Package"};
	JNI::jClassID jSavedCrosswordClass {"com/zapp/acw/bll/SavedCrossword"};

//Java method and field signatures
	JNI::jCallableID jGameStateInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jLoadFromMethod {JNI::JMETHOD, "loadFrom", "(Ljava/lang/String;)V"};

	JNI::jCallableID jDeckInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jPackField {JNI::JFIELD, "pack", "Lcom/zapp/acw/bll/Package;"};
	JNI::jCallableID jDeckIDField {JNI::JFIELD, "deckID", "I"};
	JNI::jCallableID jDeckNameField {JNI::JFIELD, "name", "Ljava/lang/String;"};

	JNI::jCallableID jPackageInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jPathField {JNI::JFIELD, "path", "Ljava/lang/String;"};
	JNI::jCallableID jPackageNameField {JNI::JFIELD, "name", "Ljava/lang/String;"};
	JNI::jCallableID jDecksField {JNI::JFIELD, "decks", "Ljava/util/ArrayList;"};
	JNI::jCallableID jStateField {JNI::JFIELD, "state", "Lcom/zapp/acw/bll/GameState;"};

	JNI::jCallableID jSCWInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jSCWPathField {JNI::JFIELD, "path", "Ljava/lang/String;"};
	JNI::jCallableID jSCWPackageNameField {JNI::JFIELD, "packageName", "Ljava/lang/String;"};
	JNI::jCallableID jSCWNameField {JNI::JFIELD, "name", "Ljava/lang/String;"};
	JNI::jCallableID jSCWWidthField {JNI::JFIELD, "width", "I"};
	JNI::jCallableID jSCWHeightField {JNI::JFIELD, "height", "I"};
	JNI::jCallableID jSCWWordsField {JNI::JFIELD, "words", "Ljava/util/HashSet;"};

//Register jni calls
	JNI::CallRegister<jGameStateClass, jGameStateInitMethod, jLoadFromMethod> JNI_GameStateClass;
	JNI::CallRegister<jDeckClass, jDeckInitMethod, jPackField, jDeckIDField, jDeckNameField> JNI_DeckClass;
	JNI::CallRegister<jPackageClass, jPackageInitMethod, jPathField, jPackageNameField, jDecksField, jStateField> JNI_PackageClass;
	JNI::CallRegister<jSavedCrosswordClass, jSCWInitMethod, jSCWPathField, jSCWPackageNameField, jSCWNameField, jSCWWidthField, jSCWHeightField, jSCWWordsField> JNI_SavedCrosswordClass;
}

GameState::GameState () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jGameStateClass), JNI::JavaMethod (jGameStateInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void GameState::LoadFrom (const std::string& path) const {
	JNI::GetEnv ()->CallVoidMethod (mObject, JNI::JavaMethod (jLoadFromMethod), JavaString (path).get ());
}

Deck::Deck () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jDeckClass), JNI::JavaMethod (jDeckInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

Package Deck::GetPack () const {
	return JNI::GetObjectField<Package> (mObject, JNI::JavaField (jPackField));
}

void Deck::SetPack (const Package& pack) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jPackField), pack.get ());
}

int Deck::GetDeckID () const {
	return JNI::GetEnv ()->GetIntField (mObject, JNI::JavaField (jDeckIDField));
}

void Deck::SetDeckID (int deckID) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jDeckIDField), deckID);
}

std::string Deck::GetName () const {
	return JNI::GetObjectField<JavaString> (mObject, JNI::JavaField (jDeckNameField)).getString ();
}

void Deck::SetName (const std::string& name) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jDeckNameField), JavaString (name).get ());
}

Package::Package () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jPackageClass), JNI::JavaMethod (jPackageInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

std::string Package::GetPath () const {
	return JNI::GetObjectField<JavaString> (mObject, JNI::JavaField (jPathField)).getString ();
}

void Package::SetPath (const std::string& path) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jPathField), JavaString (path).get ());
}

void Package::SetName (const std::string& name) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jPackageNameField), JavaString (name).get ());
}

void Package::SetDecks (const JavaArrayList<Deck>& decks) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jDecksField), decks.get ());
}

void Package::SetState (const GameState& state) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jStateField), state.get ());
}

SavedCrossword::SavedCrossword () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jSavedCrosswordClass), JNI::JavaMethod (jSCWInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void SavedCrossword::SetPath (const std::string& path) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jSCWPathField), JavaString (path).get ());
}

void SavedCrossword::SetPackageName (const std::string& packageName) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jSCWPackageNameField), JavaString (packageName).get ());
}

void SavedCrossword::SetName (const std::string& name) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jSCWNameField), JavaString (name).get ());
}

void SavedCrossword::SetWidth (int width) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jSCWWidthField), width);
}

void SavedCrossword::SetHeight (int height) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jSCWHeightField), height);
}

void SavedCrossword::SetWords (const JavaHashSet& words) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jSCWWordsField), words.get ());
}
