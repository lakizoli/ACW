package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class PersianKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u0636",  "\u0635",  "\u062b",  "\u0642",  "\u0641",  "\u063a",  "\u0639",  "\u0647",  "\u062e",  "\u062d",  "\u062c", BACKSPACE));
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
					outKeys   .addAll (Arrays.asList ( "\u0634",  "\u0633",  "\u06cc",  "\u0628",  "\u0644",  "\u0627",  "\u062a",  "\u0646",  "\u0645",  "\u06a9",  "\u06af", ENTER));
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
					outKeys   .addAll (Arrays.asList ( "\u067e",  "\u0638",  "\u0637",  "\u0632",  "\u0631",  "\u0630",  "\u062f",  "\u0626",  "\u0648",  "\u0686",  "\u067e"));
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

		return false;
	}
}
