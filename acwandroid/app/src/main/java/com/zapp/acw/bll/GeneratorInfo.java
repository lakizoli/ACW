package com.zapp.acw.bll;

import java.util.ArrayList;
import java.util.TreeMap;

public class GeneratorInfo {
//Database properties
	public ArrayList<Deck> decks = new ArrayList<> ();
	public ArrayList<Card> cards = new ArrayList<> ();
	public ArrayList<Field> fields = new ArrayList<> ();
	public ArrayList<String> usedWords = new ArrayList<> ();

//Configured properties
	public String crosswordName;
	public int width;
	public int height;
	public int questionFieldIndex;
	public int solutionFieldIndex;
	public ArrayList<String> splitArray;
	public TreeMap<String, String> solutionsFixes;
}
