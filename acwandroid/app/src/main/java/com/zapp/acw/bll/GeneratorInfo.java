package com.zapp.acw.bll;

import java.util.ArrayList;
import java.util.TreeMap;

public final class GeneratorInfo {
//Database properties
	public ArrayList<Deck> decks = new ArrayList<> ();
	public ArrayList<Card> cards = new ArrayList<> ();
	public ArrayList<Field> fields = new ArrayList<> ();
	public ArrayList<String> usedWords = new ArrayList<> ();

//Configured properties
	public String crosswordName;
	public int width = 0;
	public int height = 0;
	public int questionFieldIndex = 0;
	public int solutionFieldIndex = 0;
	public ArrayList<String> splitArray = new ArrayList<> ();
	public TreeMap<String, String> solutionsFixes = new TreeMap<> ();
}
