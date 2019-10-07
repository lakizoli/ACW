package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class JapanKatakanaKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u30bf", "\u30c6", "\u30a4",  "\u30b9",  "\u30ab",  "\u30f3",  "\u30ca",  "\u30cb",  "\u30e9",  "\u30bb",  "\u30d8",  "\u30e0", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,      1.0,      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("\u30ed",  "\u30cc",  "\u30d5",  "\u30a2",  "\u30a6",  "\u30a8",  "\u30aa",  "\u30e4",  "\u30e6",  "\u30e8",  "\u30ef",  "\u30db", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u30c1",  "\u30c8",  "\u30b7",  "\u30cf",  "\u30ad",  "\u30af",  "\u30de",  "\u30ce",  "\u30ea",  "\u30ec",  "\u30b1", ENTER));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9",  "Ex10",  "Ex11", ENTER));
					outWeights.addAll (Arrays.asList (  1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,     1.0,     1.0,   2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u30c4",  "\u30b5",  "\u30bd",  "\u30d2",  "\u30b3",  "\u30df",  "\u30e2",  "\u30cd",  "\u30eb",  "\u30e1",  "\u309b",  "\u309c"));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17",  "Ex18",  "Ex19",  "Ex20",  "Ex21",  "Ex22",  "Ex23"));
					outWeights.addAll (Arrays.asList (   1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
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
