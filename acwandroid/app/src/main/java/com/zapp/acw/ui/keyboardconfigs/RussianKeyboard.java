package com.zapp.acw.ui.keyboardconfigs;

import com.zapp.acw.ui.keyboard.KeyboardConfig;

import java.util.ArrayList;
import java.util.Arrays;

public class RussianKeyboard extends KeyboardConfig {
	@Override
	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page >= BASIC_PAGE_COUNT) {
			return super.rowKeys (row, page, outKeys, outWeights);
		}

		switch (row) {
			case 0:
				if (page == PAGE_ALPHA) {
					outKeys.addAll (Arrays.asList ("\u0439".toUpperCase (), "\u0446".toUpperCase (), "\u0443".toUpperCase (), "\u043a".toUpperCase (),
							"\u0435".toUpperCase (), "\u043d".toUpperCase (), "\u0433".toUpperCase (), "\u0448".toUpperCase (),
							"\u0449".toUpperCase (), "\u0437".toUpperCase (), "\u0445".toUpperCase (), BACKSPACE));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys.addAll (Arrays.asList ("1", "2", "3", "4", "5", "6", "7", "8", "9", "0", BACKSPACE));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
					return true;
				}
				break;
			case 1:
				if (page == PAGE_ALPHA) {
					outKeys.addAll (Arrays.asList ("\u0444".toUpperCase (), "\u044b".toUpperCase (), "\u0432".toUpperCase (), "\u0430".toUpperCase (),
							"\u043f".toUpperCase (), "\u0440".toUpperCase (), "\u043e".toUpperCase (), "\u043b".toUpperCase (),
							"\u0434".toUpperCase (), "\u0436".toUpperCase (), "\u044d".toUpperCase (), ENTER));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys.addAll (Arrays.asList ("Ex1", "Ex2", "Ex3", "Ex4", "Ex5", "Ex6", "Ex7", "Ex8", "Ex9", "Ex10", "Ex11", ENTER));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
					return true;
				}
				break;
			case 2:
				if (page == PAGE_ALPHA) {
					outKeys.addAll (Arrays.asList ("\u044f".toUpperCase (), "\u0447".toUpperCase (), "\u0441".toUpperCase (), "\u043c".toUpperCase (),
							"\u0438".toUpperCase (), "\u0442".toUpperCase (), "\u044c".toUpperCase (), "\u0431".toUpperCase (),
							"\u044e".toUpperCase (), "\u0451".toUpperCase (), "\u044a".toUpperCase ()));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0));
					return true;
				} else if (page == PAGE_NUM) {
					outKeys.addAll (Arrays.asList ("Ex12", "Ex13", "Ex14", "Ex15", "Ex16", "Ex17", "Ex18", "Ex19", "Ex20", "Ex21", "Ex22"));
					outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0));
					return true;
				}
				break;
			case 3:
				if (page == PAGE_ALPHA || page == PAGE_NUM) {
					outKeys.addAll (Arrays.asList (SWITCH, SPACEBAR, TURNOFF));
					outWeights.addAll (Arrays.asList (1.0, 3.0, 1.0));
					return true;
				}
				break;
			default:
				break;
		}

		return false;
	}
}
