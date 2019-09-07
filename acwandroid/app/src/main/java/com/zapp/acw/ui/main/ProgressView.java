package com.zapp.acw.ui.main;

import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.IdRes;
import androidx.fragment.app.FragmentActivity;

public class ProgressView {
	private TextView _textView;
	private ProgressBar _progressBar;
	private Button _button;
	private Runnable _onButtonPressed;

	public ProgressView (FragmentActivity activity, @IdRes int textViewID, @IdRes int progressBarID, @IdRes int buttonID) {
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

	public void setLabel (String label) {
		_textView.setText (label);
	}

	public void setProgress (int progress) {
		_progressBar.setProgress (progress);
	}

	public void setButtonText (String text) {
		_button.setText (text);
	}

	public void setOnButtonPressed (Runnable press) {
		_onButtonPressed = press;
	}

	public void setVisibility (int visibility) {
		_textView.setVisibility (visibility);
		_progressBar.setVisibility (visibility);
		_button.setVisibility (visibility);

		if (visibility == View.VISIBLE) {
			_progressBar.setProgress (0);
		}
	}
}
