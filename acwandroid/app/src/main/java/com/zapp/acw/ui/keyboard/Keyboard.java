package com.zapp.acw.ui.keyboard;

import android.view.View;
import android.widget.LinearLayout;

import com.zapp.acw.R;

import java.util.ArrayList;
import java.util.HashSet;

import androidx.fragment.app.FragmentActivity;

public class Keyboard {
	public void showKeyboard (FragmentActivity activity) {
		LinearLayout keyboard = activity.findViewById (R.id.cwview_keyboard);
		keyboard.setVisibility (View.VISIBLE);
	}

	public void setUsedKeys (HashSet<String> usedKeys) {
	}

	public void setup () {
		//TODO: ...
	}

	//region Setup buttons
	private void createPage (int page) {
		ArrayList<String> keys = null;
		ArrayList<Integer> weights = null;
		for (int row = 0; row < 4; ++row) {
			keys = new ArrayList<> ();
			weights = new ArrayList<> ();

//			if ([_keyboardConfig rowKeys:row page:page outKeys:&keys outWeights:&weights] == YES) {
//				[self createButtonsForKeys:keys
//					weights:weights
//					destination:[_rowViews objectAtIndex:row]
//					buttonStorage:_rowButtons[row]
//					constraintStorage:_constraints[row]];
//			}
		}
	}
	//endregion
}
