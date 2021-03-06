package com.zapp.acw.ui.keyboard;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Color;
import android.graphics.Typeface;
import android.util.Log;
import android.util.TypedValue;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import com.zapp.acw.R;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Timer;
import java.util.TimerTask;

import androidx.annotation.DrawableRes;
import androidx.core.content.res.ResourcesCompat;
import androidx.core.widget.TextViewCompat;
import androidx.fragment.app.FragmentActivity;

import static com.zapp.acw.ui.keyboard.KeyboardConfig.BACKSPACE;
import static com.zapp.acw.ui.keyboard.KeyboardConfig.ENTER;
import static com.zapp.acw.ui.keyboard.KeyboardConfig.SPACEBAR;
import static com.zapp.acw.ui.keyboard.KeyboardConfig.SWITCH;
import static com.zapp.acw.ui.keyboard.KeyboardConfig.TURNOFF;

public class Keyboard {
	private static final int _doneColor = Color.rgb (13, 57, 228);
	private static final int _highlightColor = Color.rgb (229,193,71);
	private static int _greenColor = 0;

	private HashSet<String> _usedKeys;

	private KeyboardConfig _keyboardConfig;
	private int _currentPage = 0;

	private EventHandler _eventHandler;

	public interface EventHandler {
		void deleteBackward ();
		void insertText (String text);
		void dismissKeyboard ();
	}

	public void setEventHandler (EventHandler eventHandler) {
		_eventHandler = eventHandler;
	}

	public void showKeyboard (FragmentActivity activity) {
		LinearLayout keyboard = activity.findViewById (R.id.cwview_keyboard);
		keyboard.setVisibility (View.VISIBLE);

		LinearLayout cwLayout = activity.findViewById (R.id.cwview_cwlayout);
		RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams) cwLayout.getLayoutParams ();
		params.setMargins (0, 0, 0, getDPSizeInPixels (activity, 280));
		cwLayout.setLayoutParams (params);

		_greenColor = activity.getResources ().getColor (R.color.colorGreenBack);
	}

	public void hideKeyboard (FragmentActivity activity) {
		LinearLayout keyboard = activity.findViewById (R.id.cwview_keyboard);
		keyboard.setVisibility (View.INVISIBLE);

		LinearLayout cwLayout = activity.findViewById (R.id.cwview_cwlayout);
		RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams) cwLayout.getLayoutParams ();
		params.setMargins (0, 0, 0, 0);
		cwLayout.setLayoutParams (params);
	}

	public void setUsedKeys (HashSet<String> usedKeys) {
		_usedKeys = usedKeys;
	}

	public void setup (FragmentActivity activity) {
		_keyboardConfig = chooseBestFitKeyboard ();
		createPage (activity, _currentPage);
	}

	//region Setup buttons
	private void createPage (final FragmentActivity activity, int page) {
		ArrayList<LinearLayout> layouts = new ArrayList<LinearLayout> () {{
			add ((LinearLayout) activity.findViewById (R.id.cwview_keyboard_row1));
			add ((LinearLayout) activity.findViewById (R.id.cwview_keyboard_row2));
			add ((LinearLayout) activity.findViewById (R.id.cwview_keyboard_row3));
			add ((LinearLayout) activity.findViewById (R.id.cwview_keyboard_row4));
		}};

		for (final LinearLayout layout : layouts) {
			activity.runOnUiThread (new Runnable () {
				@Override
				public void run () {
					layout.removeAllViews ();
				}
			});
		}

		ArrayList<String> keys;
		ArrayList<Double> weights;
		for (int row = 0; row < 4; ++row) {
			keys = new ArrayList<> ();
			weights = new ArrayList<> ();

			if (_keyboardConfig.rowKeys (row, page, keys, weights)) {
				createButtonsForKeys (activity, page, keys, weights, layouts.get (row));
			}
		}
	}

	private void createButtonsForKeys (final FragmentActivity activity, int page, ArrayList<String> keys, ArrayList<Double> weights, final LinearLayout destination) {
		double sumWeight = 0;
		for (double weight : weights) {
			sumWeight += weight;
		}
		sumWeight += (weights.size () - 1) * 0.05; //The weights of the spacers

		for (int idx = 0; idx < keys.size (); ++idx) {
			final String key = keys.get (idx);
			final double widthRatio = weights.get (idx) / sumWeight;
			final double spacerWidthRatio = 0.05 / sumWeight;
			final boolean addSpacer = idx > 0;

			if (key.equalsIgnoreCase (BACKSPACE)) {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						addImageView (activity, key, widthRatio, spacerWidthRatio, R.drawable.backspace_keyboard, addSpacer, destination);

					}
				});
			} else if (key.equalsIgnoreCase (ENTER)) {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						Button button = addTextButton (activity, key, widthRatio, spacerWidthRatio, "Done", addSpacer, destination);
						button.setBackgroundColor (_doneColor);
					}
				});
			} else if (key.equalsIgnoreCase (SPACEBAR)) {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						addTextButton (activity, key, widthRatio, spacerWidthRatio, "Space", addSpacer, destination);
					}
				});
			} else if (key.equalsIgnoreCase (TURNOFF)) {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						addImageView (activity, key, widthRatio, spacerWidthRatio, R.drawable.turn_off_keyboard, addSpacer, destination);
					}
				});
			} else if (key.equalsIgnoreCase (SWITCH)) {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						addImageView (activity, key, widthRatio, spacerWidthRatio, R.drawable.switch_keyboard, addSpacer, destination);
					}
				});
			} else if (key.startsWith ("Ex")) { //Extra key
				final int extraKeyID = _keyboardConfig.getExtraKeyID (key, page);
				if (extraKeyID > 0) { //Used extra key
					activity.runOnUiThread (new Runnable () {
						@Override
						public void run () {
							Button button = addTextButton (activity, key, widthRatio, spacerWidthRatio, "", addSpacer, destination);
							button.setTag (Integer.valueOf (extraKeyID));

							String title = _keyboardConfig.getTitleForExtraKeyID (extraKeyID);
							if (title != null && title.length () > 0) {
//								Log.d ("title: " + title);
								button.setText (title);
							}

						}
					});
				} else { //Unused extra key
					activity.runOnUiThread (new Runnable () {
						@Override
						public void run () {
							addSpacerView (activity, widthRatio + (addSpacer ? spacerWidthRatio : 0), destination);

						}
					});
				}
			} else { //Normal value key
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						addTextButton (activity, key, widthRatio, spacerWidthRatio, key, addSpacer, destination);
					}
				});
			}
		}
	}

	private Button addTextButton (FragmentActivity activity, String key, double weight, double spacerWeight,
								  String text, boolean addSpacer, LinearLayout destination)
	{
		if (addSpacer) {
			addSpacerView (activity, spacerWeight, destination);
		}

		Button button = new Button (activity);
		destination.addView (button);

		button.setText (text);

		Typeface typeface = ResourcesCompat.getFont (button.getContext (), R.font.bradley_hand);
		button.setTypeface (typeface);
		TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration (button, 3, 26, 1, TypedValue.COMPLEX_UNIT_SP);

		LinearLayout.LayoutParams params= new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT);
		params.width = 0;
		params.weight = (float) weight;
		button.setLayoutParams (params);

		float[] hsv = new float[3];
		Color.RGBToHSV (229, 193, 71, hsv);
		int textColor = Color.HSVToColor (hsv);

		button.setTextColor (textColor);
		button.setBackgroundColor (activity.getResources ().getColor (R.color.colorGreenBack));

		setupButtonsAction (button, key);
		return button;
	}

	private void addImageView (FragmentActivity activity, String key, double weight, double spacerWeight,
							   @DrawableRes int image, boolean addSpacer, LinearLayout destination)
	{
		if (addSpacer) {
			addSpacerView (activity, spacerWeight, destination);
		}

		ImageView imageView = new ImageView (activity);
		destination.addView (imageView);

		imageView.setImageResource (image);

		LinearLayout.LayoutParams params= new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT);
		params.width = 0;
		params.weight = (float) weight;
		imageView.setLayoutParams (params);

		imageView.setBackgroundColor (activity.getResources ().getColor (R.color.colorGreenBack));

		setupButtonsAction (imageView, key);
	}

	private void addSpacerView (FragmentActivity activity, double weight, LinearLayout destination) {
		View view = new View (activity);

		LinearLayout.LayoutParams params= new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT);
		params.width = 0;
		params.weight = (float) weight;
		view.setLayoutParams (params);

		destination.addView (view);
	}

	private void setupButtonsAction (View view, String key) {
		if (key.equalsIgnoreCase (BACKSPACE)) {
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					backSpacePressed ();
				}
			});
		} else if (key.equalsIgnoreCase (ENTER)) {
			view.setOnTouchListener (new ButtonTouchListener (true));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					enterPressed ();
				}
			});
		} else if (key.equalsIgnoreCase (SPACEBAR)) {
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					spacePressed ();
				}
			});
		} else if (key.equalsIgnoreCase (TURNOFF)) {
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					turnOffPressed ();
				}
			});
		} else if (key.equalsIgnoreCase (SWITCH)) {
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					switchPressed (v);
				}
			});
		} else if (key.startsWith ("Ex")) { //Extra key
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					extraKeyPressed (v);
				}
			});
		} else { //Normal value key
			view.setOnTouchListener (new ButtonTouchListener (false));
			view.setOnClickListener (new View.OnClickListener () {
				@Override
				public void onClick (View v) {
					keyPressed (v);
				}
			});
		}
	}

	private KeyboardConfig chooseBestFitKeyboard () {
		try {
			ArrayList<Class> keyboardClasses = new ArrayList<Class> () {{
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.USKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.HunKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.GreekKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.RussianKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.Arabic102Keyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.PersianKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.HindiTraditionalKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.JapanKatakanaKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.JapanHiraganaKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.ThaiKedmaneeKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.ThaiPattachoteKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.ChineseBopomofoKeyboard"));
				add (Class.forName ("com.zapp.acw.ui.keyboardconfigs.ChineseChaJeiKeyboard"));
			}};

			KeyboardConfig cfg = null;
			HashSet<String> extraKeys = null;
			int extraKeyCount = Integer.MAX_VALUE;

			for (Class cls : keyboardClasses) {
				KeyboardConfig kb = (KeyboardConfig) cls.newInstance ();

				HashSet<String> kbExtraKeys = kb.collectExtraKeys (_usedKeys);
				int kbExtraKeyCount = kbExtraKeys == null ? 0 : kbExtraKeys.size ();
				if (kbExtraKeyCount <= 0) { //We found a full keyboard without needing any extra keys
					cfg = kb;
					extraKeys = kbExtraKeys;
					extraKeyCount = kbExtraKeyCount;

					break;
				} else if (kbExtraKeyCount < extraKeyCount) { //We found a keyboard config with lower extra button needs
					cfg = kb;
					extraKeys = kbExtraKeys;
					extraKeyCount = kbExtraKeyCount;
				}
			}

			if (extraKeyCount > 0) {
				cfg.addExtraPages (extraKeys);
			}

			return cfg;
		} catch (Exception ex) {
			Log.e ("Keyboard", "chooseBestFitKeyboard - Exception: " + ex.toString ());
		}

		return null;
	}

	private FragmentActivity getActivityFromView (View view) {
		Context context = view.getContext ();
		while (context instanceof ContextWrapper) {
			if (context instanceof FragmentActivity) {
				return (FragmentActivity) context;
			}
			context = ((ContextWrapper) context).getBaseContext ();
		}
		return null;
	}

	private class ButtonTouchListener implements View.OnTouchListener {
		private boolean _isDoneHandler = false;

		public ButtonTouchListener (boolean isDoneHandler) {
			_isDoneHandler = isDoneHandler;
		}

		@Override
		public boolean onTouch (final View view, MotionEvent event) {
			switch (event.getAction ()) {
				case MotionEvent.ACTION_DOWN:
					view.setBackgroundColor (_highlightColor);
					break;
				case MotionEvent.ACTION_UP:
					view.setBackgroundColor (_isDoneHandler ? _doneColor : _greenColor);
					break;
				default:
					break;
			}

			return false;
		}
	}

	private static int getDPSizeInPixels (Context context, int dpSize) {
		final float scale = context.getResources().getDisplayMetrics().density;
		return Math.round (dpSize * scale + 0.5f);
	}
	//endregion

	//region Key events
	private void backSpacePressed () {
		if (_eventHandler != null) {
			_eventHandler.deleteBackward ();
		}
	}

	private void enterPressed () {
		if (_eventHandler != null) {
			_eventHandler.insertText ("\n");
		}
	}

	private void spacePressed () {
		if (_eventHandler != null) {
			_eventHandler.insertText (" ");
		}
	}

	private void turnOffPressed () {
		if (_eventHandler != null) {
			_eventHandler.dismissKeyboard ();
		}
	}

	private void switchPressed (View sender) {
		++_currentPage;
		if (_currentPage >= _keyboardConfig.getPageCount ()) {
			_currentPage = 0;
		}

		createPage (getActivityFromView (sender), _currentPage);
	}

	private void extraKeyPressed (View sender) {
		if (sender instanceof Button && _eventHandler != null) {
			Button button = (Button) sender;
			int extraKeyID = (Integer) button.getTag ();
			if (extraKeyID > 0) {
				String value = _keyboardConfig.getValueForExtraKeyID (extraKeyID);
				if (value != null && value.length () > 0) {
					_eventHandler.insertText (value);
				}
			}
		}
	}

	private void keyPressed (View sender) {
		if (sender instanceof Button && _eventHandler != null) {
			Button button = (Button) sender;
			String key = button.getText ().toString ();
			_eventHandler.insertText (key);
		}
	}
	//endregion
}
