package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class HindiTraditionalKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u094c",  "\u0948",  "\u093e",  "\u0940",  "\u0942",  "\u092c",  "\u0939",  "\u0917",  "\u0926",  "\u091c",  "\u0943", BACKSPACE));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "0", BACKSPACE));
					outWeights.addAll (Arrays.asList ( 1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u094b",  "\u0947",  "\u094d",  "\u093f",  "\u0941",  "\u092a",  "\u0930",  "\u0915",  "\u0924",  "\u091a",  "\u091f", ENTER));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9",  "Ex10",  "Ex11", ENTER));
					outWeights.addAll (Arrays.asList (   1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,     1.0,     1.0,   2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u0949",  "\u0902",  "\u092e",  "\u0928",  "\u0935",  "\u0932",  "\u0938",  "\u092f",  "\u0921",  "\u093c",  "\u0949"));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17",  "Ex18",  "Ex19",  "Ex20",  "Ex21",  "Ex22"));
					outWeights.addAll (Arrays.asList (    1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
					return true;
				}
				break;
			case 3:
				if (page == PAGE_ALPHA || page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList (SWITCH, SPACEBAR, TURNOFF));
					outWeights.addAll (Arrays.asList (   1.0,      3.0,     1.0));
					return true;
				}
				break;
			default:
				break;
		}

		return true;
	}
}
