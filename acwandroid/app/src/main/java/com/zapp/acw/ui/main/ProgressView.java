package com.zapp.acw.ui.main;

import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.IdRes;
import androidx.annotation.StringRes;
import androidx.fragment.app.FragmentActivity;

public class ProgressView {
	private LinearLayout _view;
	private TextView _textView;
	private ProgressBar _progressBar;
	private Button _button;
	private Runnable _onButtonPressed;

	public ProgressView (FragmentActivity activity, @IdRes int viewID, @IdRes int textViewID, @IdRes int progressBarID, @IdRes int buttonID) {
		_view = activity.findViewById (viewID);

		_textView = activity.findViewById (textViewID);
		_progressBar = activity.findViewById (progressBarID);

		_button = activity.findViewById (buttonID);
		_button.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				if (_onButtonPressed != null) {
					_onButtonPressed.run ();
				}
			}
		});
	}

	public String getString (@StringRes int res) {
		return _textView.getResources ().getString (res);
	}

	public void setLabel (@StringRes int label) {
		_textView.setText (label);
	}

	public void setLabel (String label) {
		_textView.setText (label);
	}

	public void setProgress (int progress) {
		_progressBar.setProgress (progress);
	}

	public void setButtonText (@StringRes int text) {
		_button.setText (text);
	}

	public void setOnButtonPressed (Runnable press) {
		_onButtonPressed = press;
	}

	public void setVisibility (int visibility) {
		_view.setVisibility (visibility);
		_textView.setVisibility (visibility);
		_progressBar.setVisibility (visibility);
		_button.setVisibility (visibility);

		if (visibility == View.VISIBLE) {
			_progressBar.setProgress (0);
		}
	}
}
