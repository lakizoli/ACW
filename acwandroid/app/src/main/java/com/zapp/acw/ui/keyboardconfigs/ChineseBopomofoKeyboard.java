package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

import static com.zapp.acw.ui.keyboard.KeyboardConfig.BASIC_PAGE_COUNT;

public class ChineseBopomofoKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u3106",  "\u310a",  "\u310d",  "\u3110",  "\u3114",  "\u3117",  "\u3127",  "\u311b",  "\u311f",  "\u3123", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("\u3105",  "\u3109",  "\u02c7",  "\u02cb",  "\u3113",  "\u02ca",  "\u02d9",  "\u311a",  "\u311e",  "\u3122", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u3107",  "\u310b",  "\u310e",  "\u3111",  "\u3115",  "\u3118",  "\u3128",  "\u311c",  "\u3120",  "\u3124", ENTER));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9",  "Ex10", ENTER));
					outWeights.addAll (Arrays.asList (  1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,     1.0,   2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u3108",  "\u310c",  "\u310f",  "\u3112",  "\u3116",  "\u3119",  "\u3129",  "\u311d",  "\u3121",  "\u3125",  "\u3126"));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex11",  "Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17",  "Ex18",  "Ex19",  "Ex20",  "Ex21"));
					outWeights.addAll (Arrays.asList (   1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
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