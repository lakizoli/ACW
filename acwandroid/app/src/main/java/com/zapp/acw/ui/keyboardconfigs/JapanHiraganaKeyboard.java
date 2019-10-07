package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

import static com.zapp.acw.ui.keyboard.KeyboardConfig.BASIC_PAGE_COUNT;

public class JapanHiraganaKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u305f",  "\u3066",  "\u3044",  "\u3059",  "\u304b",  "\u3093",  "\u306a",  "\u306b",  "\u3089",  "\u305b",  "\u3080",  "\u3078", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("\u308d",  "\u306c",  "\u3075",  "\u3042",  "\u3046",  "\u3048",  "\u304a",  "\u3084",  "\u3086",  "\u3088",  "\u308f",  "\u307b", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u3061",  "\u3068",  "\u3057",  "\u306f",  "\u304d",  "\u304f",  "\u307e",  "\u306e",  "\u308a",  "\u308c",  "\u3051", ENTER));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9",  "Ex10",  "Ex11", ENTER));
					outWeights.addAll (Arrays.asList (  1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,     1.0,    1.0,    2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u3064",  "\u3055",  "\u305d",  "\u3072",  "\u3053",  "\u307f",  "\u3082",  "\u306d",  "\u308b",  "\u3081",  "\u309b",  "\u309c"));
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
