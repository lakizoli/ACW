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

//Register jni calls
	JNI::CallRegister<jGameStateClass, jGameStateInitMethod, jLoadFromMethod> JNI_GameStateClass;
	JNI::CallRegister<jDeckClass, jDeckInitMethod, jPackField, jDeckIDField, jDeckNameField> JNI_DeckClass;
	JNI::CallRegister<jPackageClass, jPackageInitMethod, jPathField, jPackageNameField, jDecksField, jStateField> JNI_PackageClass;
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

void Deck::SetPack (const Package& pack) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jPackField), pack.get ());
}

void Deck::SetDeckID  (int deckID) {
	JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jDeckIDField), deckID);
}

void Deck::SetName (const std::string& name) {
	JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jDeckNameField), JavaString (name).get ());
}

Package::Package () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jPackageClass), JNI::JavaMethod (jPackageInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
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

