package com.zapp.acw.bll;

import java.util.ArrayList;
import java.util.HashMap;

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
	public ArrayList<String> splitArray;
	public HashMap<String, String> solutionsFixes = new HashMap<> ();

	public GeneratorInfo () {
		splitArray = new ArrayList<String> () {{
			add (";"); add ("\uff1b"); add ("<br"); add ("/>"); add ("<div>"); add ("</div>");
			add ("<span>"); add ("</span>"); add ("*"); add ("\r"); add ("\n"); add (","); add ("\uff0c"); add ("("); add ("\uff08"); add (")"); add ("\uff09");
			add ("["); add ("\uff3b"); add ("]"); add ("\uff3d"); add ("{"); add ("\uff5b"); add ("}"); add ("\uff5d");
		}};
	}
}
