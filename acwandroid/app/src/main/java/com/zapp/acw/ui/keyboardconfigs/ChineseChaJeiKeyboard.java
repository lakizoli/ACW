package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class ChineseChaJeiKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u624b",  "\u7530",  "\u6c34",  "\u53e3",  "\u5eff",  "\u535c",  "\u5c71",  "\u6208", BACKSPACE));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "0", BACKSPACE));
					outWeights.addAll (Arrays.asList (1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,       2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\u65e5",  "\u5c38",  "\u6728",  "\u706b",  "\u571f",  "\u7af9",  "\u5341",  "\u5927",  "\u4e2d", ENTER));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,   2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex1",  "Ex2",  "Ex3",  "Ex4",  "Ex5",  "Ex6",  "Ex7",  "Ex8",  "Ex9", ENTER));
					outWeights.addAll (Arrays.asList (  1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,    1.0,   2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys   .addAll (Arrays.asList ("\uff3a",  "\u96e3",  "\u91d1",  "\u5973",  "\u6708",  "\u5f13",  "\u4e00",  "\u4eba",  "\u5fc3"));
					outWeights.addAll (Arrays.asList (     1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0,       1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys   .addAll (Arrays.asList ("Ex10",  "Ex11",  "Ex12",  "Ex13",  "Ex14",  "Ex15",  "Ex16",  "Ex17",  "Ex18"));
					outWeights.addAll (Arrays.asList (   1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0,     1.0));
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
