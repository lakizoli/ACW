package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class GreekKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u03c2",  "\u03b5",  "\u03c1",  "\u03c4",  "\u03c5",  "\u03b8",  "\u03b9",  "\u03bf",  "\u03c0", BACKSPACE));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "0", BACKSPACE));
					outWeights.addAll (Arrays.asList ( 1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u03b1",  "\u03c3",  "\u03b4",  "\u03c6",  "\u03b3",  "\u03b7",  "\u03be",  "\u03ba",  "\u03bb",  "\u0384", ENTER));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9",  "Ex10", ENTER));
					outWeights.addAll (Arrays.asList (   1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,     1.0,   2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u03b6",  "\u03c7",  "\u03c8",  "\u03c9",  "\u03b2",  "\u03bd",  "\u03bc"));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "Ex11",  "Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17"));
					outWeights.addAll (Arrays.asList (    1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
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
