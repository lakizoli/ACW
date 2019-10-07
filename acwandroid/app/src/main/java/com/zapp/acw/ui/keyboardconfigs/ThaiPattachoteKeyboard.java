package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class ThaiPattachoteKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u0e47",  "\u0e15",  "\u0e22",  "\u0e2d",  "\u0e23",  "\u0e48",  "\u0e14",  "\u0e21",  "\u0e27",  "\u0e41",  "\u0e43", BACKSPACE));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "\u0e52",  "\u0e53",  "\u0e54",  "\u0e55",  "\u0e39",  "\u0e57",  "\u0e58",  "\u0e59",  "\u0e50",  "\u0e51",  "\u0e56", BACKSPACE));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ( "\u0e49",  "\u0e17",  "\u0e07",  "\u0e01",  "\u0e31",  "\u0e35",  "\u0e32",  "\u0e19",  "\u0e40",  "\u0e44",  "\u0e02", ENTER));
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
					outKeys   .addAll (Arrays.asList ( "\u0e1a",  "\u0e1b",  "\u0e25",  "\u0e2b",  "\u0e34",  "\u0e04",  "\u0e2a",  "\u0e30",  "\u0e08",  "\u0e1e",  "\u0e0c",  "\uf8c7"));
					outWeights.addAll (Arrays.asList (      1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ( "Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17",  "Ex18",  "Ex19",  "Ex20",  "Ex21",  "Ex22",  "Ex23"));
					outWeights.addAll (Arrays.asList (    1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
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
