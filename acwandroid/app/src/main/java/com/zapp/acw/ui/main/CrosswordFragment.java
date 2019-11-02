package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.widget.TextView;

import com.zapp.acw.R;
import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.Pos;
import com.zapp.acw.bll.SavedCrossword;
import com.zapp.acw.bll.Statistics;
import com.zapp.acw.bll.SubscriptionManager;
import com.zapp.acw.ui.keyboard.Keyboard;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.SimpleTimeZone;
import java.util.Timer;
import java.util.TimerTask;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;

public class CrosswordFragment extends BackgroundInitFragment implements Toolbar.OnMenuItemClickListener, Keyboard.EventHandler {
	private CrosswordViewModel mViewModel;
	private Keyboard mKeyboard;

	//Common view data
	private boolean _areAnswersVisible = false;
	private HashMap<Pos, String> _cellFilledValues = new HashMap<> (); ///< The current fill state of the whole grid.

	//Text input
	private boolean _canBecameFirstResponder = false;
	private String _currentAnswer = null;
	private int _maxAnswerLength = 0;
	private int _startCellRow = -1;
	private int _startCellCol = -1;
	private int _answerIndex = -1; ///< The rolling index of the current answer selected for input, when multiple answers are available in a start cell = 0.
	private ArrayList<Integer> _availableAnswerDirections = null; ///< All of the available input directions can be originated from the current start cell.

	//Statistics
	private int _failCount = 0;
	private int _hintCount = 0;
	private Calendar _startTime = Calendar.getInstance ();
	private boolean _isFilled = false;

	//Win screen effects
	private boolean _isWinScreenOn = false;
	private Timer _timerWin;
//	EmitterEffect *_emitterWin[4];
	private int _starCount = 0;

	public static CrosswordFragment newInstance () {
		return new CrosswordFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.crossword_fragment, container, false);
	}

	@Override
	public void onDestroyView () {
		mKeyboard.setEventHandler (null);
		super.onDestroyView ();
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mViewModel = ViewModelProviders.of (this).get (CrosswordViewModel.class);

		final FragmentActivity activity = getActivity ();
		final Keyboard.EventHandler keyboardEventHandler = this;

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.cwview_toolbar);
		toolbar.inflateMenu (R.menu.cwview_menu);
		toolbar.setOnMenuItemClickListener (this);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				backButtonPressed ();
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				backButtonPressed ();
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		Button congratsButton = activity.findViewById (R.id.cwview_win_close_button);
		congratsButton.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				congratsButtonPressed ();
			}
		});

		final ProgressBar progressCW = activity.findViewById (R.id.cwview_progress);
		progressCW.setVisibility (View.VISIBLE);

		mViewModel.setInitEndedObserver (new BackgroundInitViewModel.InitEndedObserver () {
			@Override
			public void onInitEnded () {
				//Init crossword
				final SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
				NetLogger.logEvent ("Crossword_ShowView", new HashMap<String, Object> () {{
					put ("package", savedCrossword.packageName);
					put ("name", savedCrossword.name);
				}});

				_areAnswersVisible = false;
				_cellFilledValues = mViewModel.getCellFilledValues ();

				//Create keyboard
				mKeyboard = new Keyboard ();
				resetInput ();

				new Thread (new Runnable () {
					@Override
					public void run () {
						//Build keyboard
						mKeyboard.setUsedKeys (savedCrossword.getUsedKeys ());
						mKeyboard.setup (activity);
						mKeyboard.setEventHandler (keyboardEventHandler);

						//Reset state
						resetStatistics ();

						//Build crossword table
						createCrosswordTable (activity);
					}
				}).start ();
			}
		});

		//Init view model
		mViewModel.startInit (getArguments ());
	}

	//region Event handlers
	@Override
	public boolean onMenuItemClick (MenuItem item) {
		switch (item.getItemId ()) {
			case R.id.cwview_reset: {
				resetButtonPressed ();
				return true;
			}
			case R.id.cwview_hint: {
				hintButtonPressed ();
				return true;
			}
			default:
				break;
		}
		return false;
	}

	private void backButtonPressed () {
		if (_isWinScreenOn || isInInit ()) {
			return;
		}

		mergeStatistics ();

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		savedCrossword.unloadDB ();
		Navigation.findNavController (getView ()).navigateUp ();

		//Send netlog
		NetLogger.logEvent ("Crossword_BackPressed");
	}

	private void resetButtonPressed () {
		if (_isWinScreenOn || isInInit ()) {
			return;
		}

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();

		_cellFilledValues.clear ();
		savedCrossword.saveFilledValues (_cellFilledValues);
		rebuildCrosswordTable ();

		//Reset statistics
		resetStatistics ();
		savedCrossword.resetStatistics ();

		//Send netlog
		NetLogger.logEvent ("Crossword_ResetPressed");
	}

	private void hintButtonPressed () {
		if (_isWinScreenOn || isInInit ()) {
			return;
		}

		_areAnswersVisible = !_areAnswersVisible;

		FragmentActivity activity = getActivity ();
		Toolbar toolbar = activity.findViewById (R.id.cwview_toolbar);
		Menu menu = toolbar.getMenu ();
		MenuItem showHideButton = menu.findItem (R.id.cwview_hint);
		showHideButton.setTitle (_areAnswersVisible ? "Hide Hint" : "Show Hint");
		rebuildCrosswordTable ();

		if (_areAnswersVisible) {
			++_hintCount;

			//Send netlog
			NetLogger.logEvent ("Crossword_HintShow");
		}
	}

	private void congratsButtonPressed () {
		int starCount = _starCount;
		resetButtonPressed ();

		FragmentActivity activity = getActivity ();
		LinearLayout layout = activity.findViewById (R.id.cwview_winscreen);
		layout.setVisibility (View.INVISIBLE);

		if (starCount < 3) { //Failed
			return; //Fill again
		}

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		ArrayList<SavedCrossword> allSavedCrossword = mViewModel.getAllSavedCrossword ();

		savedCrossword.unloadDB ();
		if (mViewModel.getIsMultiLevelGame ()) {
			int nextCWIdx = mViewModel.getCurrentCrosswordIndex () + 1;
			boolean hasMoreLevel = nextCWIdx < (allSavedCrossword == null ? 0 : allSavedCrossword.size ());

			if (hasMoreLevel) { //We have more level available
				//Check subscription
				boolean isSubscribed = SubscriptionManager.sharedInstance ().isSubscribed ();
				if (isSubscribed) { //Go to the next level
//					[self performSegueWithIdentifier:@"ShowCW" sender:self];
				} else { //Show store alert
					showSubscription ();
				}
			} else { //No more level
				Navigation.findNavController (getView ()).navigateUp ();
			}
		} else { //Single level game
			Navigation.findNavController (getView ()).navigateUp ();
		}
	}
	//endregion

	//region Build crossword table
	public static final int CWCellType_Unknown					= 0x0000;
	public static final int CWCellType_SingleQuestion			= 0x0001;
	public static final int CWCellType_DoubleQuestion			= 0x0002;
	public static final int CWCellType_Spacer					= 0x0004;
	public static final int CWCellType_Letter					= 0x0008;
	public static final int CWCellType_Start_TopDown_Right		= 0x0010;
	public static final int CWCellType_Start_TopDown_Left		= 0x0020;
	public static final int CWCellType_Start_TopDown_Bottom		= 0x0040;
	public static final int CWCellType_Start_TopRight			= 0x0080;
	public static final int CWCellType_Start_FullRight			= 0x0100;
	public static final int CWCellType_Start_BottomRight		= 0x0200;
	public static final int CWCellType_Start_LeftRight_Top		= 0x0400;
	public static final int CWCellType_Start_LeftRight_Bottom	= 0x0800;
	public static final int CWCellType_HasValue					= 0x0FF8;

	private int getCellSizeInPixels () {
		final float scale = getContext().getResources().getDisplayMetrics().density;
		return Math.round (50.0f * scale + 0.5f);
	}

	private void createCrosswordTable (final FragmentActivity activity) {
		final TableLayout table = new TableLayout (activity);
		TableLayout.LayoutParams params= new TableLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
		table.setLayoutParams (params);

		int pixels = getCellSizeInPixels ();

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		LayoutInflater inflater = LayoutInflater.from (activity);

		for (int row = 0; row < savedCrossword.height;++row) {
			TableRow tableRow = new TableRow (activity);
			table.addView (tableRow);

			tableRow.setLayoutParams (new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));

			for (int col = 0; col < savedCrossword.width; ++col) {
				View cell = inflater.inflate (R.layout.crossword_cell, tableRow, false);
				tableRow.addView (cell, pixels, pixels);

				final int cellRow = row;
				final int cellCol = col;
				cell.setOnClickListener (new View.OnClickListener () {
					@Override
					public void onClick (View v) {
						if (shouldSelectCell (cellRow, cellCol)) {
							didSelectCell (cellRow, cellCol);
						}
					}
				});
			}
		}

		activity.runOnUiThread (new Runnable () {
			@Override
			public void run () {
				//Add table to scroll view
				TwoDScrollView scrollView = activity.findViewById (R.id.cwview_scroll);
				scrollView.addView (table);

				//Rebuild the cw
				rebuildCrosswordTable ();

				//Hide the progress bar
				final ProgressBar progressCW = activity.findViewById (R.id.cwview_progress);
				progressCW.setVisibility (View.INVISIBLE);

				//Sign end of init
				endInit ();
			}
		});
	}

	private void rebuildCrosswordTable () {
		final FragmentActivity activity = getActivity ();
		TwoDScrollView scrollView = activity.findViewById (R.id.cwview_scroll);
		TableLayout table = (TableLayout) scrollView.getChildAt (0);

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		for (int row = 0; row < savedCrossword.height;++row) {
			TableRow tableRow = (TableRow) table.getChildAt (row);

			for (int col = 0; col < savedCrossword.width;++col) {
				View cell = tableRow.getChildAt (col);
				buildCell (cell, row, col);
			}
		}
	}

	private boolean shouldSelectCell (int row, int col) {
		boolean startCell = mViewModel.getSavedCrossword ().isStartCell (row, col);
		_canBecameFirstResponder = startCell;
		commitValidAnswer ();
		if (startCell) {
			_currentAnswer = null;
		} else {
			resetInput ();
			rebuildCrosswordTable ();
		}
		return startCell;
	}

	private void didSelectCell (int row, int col) {
		final SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();

		//Determine answer's current direction
		final int selRow = row;
		final int selCol = col;
		final boolean isNewStart = _startCellRow < 0 || _startCellCol < 0 || _answerIndex < 0 || _startCellRow != selRow || _startCellCol != selCol;
		if (isNewStart) {
			//Collect available answer directions
			_availableAnswerDirections = new ArrayList<> ();
			int cellType = savedCrossword.getCellTypeInRow (selRow, selCol);
			addAvailableInputDirection (cellType, CWCellType_Start_TopDown_Right);
			addAvailableInputDirection (cellType, CWCellType_Start_TopDown_Left);
			addAvailableInputDirection (cellType, CWCellType_Start_TopDown_Bottom);
			addAvailableInputDirection (cellType, CWCellType_Start_TopRight);
			addAvailableInputDirection (cellType, CWCellType_Start_FullRight);
			addAvailableInputDirection (cellType, CWCellType_Start_BottomRight);
			addAvailableInputDirection (cellType, CWCellType_Start_LeftRight_Top);
			addAvailableInputDirection (cellType, CWCellType_Start_LeftRight_Bottom);
			if (_availableAnswerDirections.size () <= 0) { //Basic error check (one direction have to be available!)
				return;
			}

			//Start input of first answer
			_startCellRow = selRow;
			_startCellCol = selCol;
			_answerIndex = 0;
		} else {
			++_answerIndex;
			if (_answerIndex >= _availableAnswerDirections.size ()) {
				_answerIndex = 0;
			}
		}

		//Determine answer's available length
		_maxAnswerLength = 0;
		if (isInputInHorizontalDirection ()) {
			boolean endReached = false;
			while (!endReached) {
				++_maxAnswerLength;

				int cellType = savedCrossword.getCellTypeInRow (selRow, selCol + _maxAnswerLength);
				if (cellType == CWCellType_Unknown || cellType == CWCellType_SingleQuestion ||
					cellType == CWCellType_DoubleQuestion || cellType == CWCellType_Spacer) //End of current input word reached
				{
					endReached = true;
				}
			}
		} else {
			boolean endReached = false;
			while (!endReached) {
				++_maxAnswerLength;

				int cellType = savedCrossword.getCellTypeInRow (selRow + _maxAnswerLength, selCol);
				if (cellType == CWCellType_Unknown || cellType == CWCellType_SingleQuestion ||
					cellType == CWCellType_DoubleQuestion || cellType == CWCellType_Spacer) //End of current input word reached
				{
					endReached = true;
				}
			}
		}

		//Show keyboard
		final FragmentActivity activity = getActivity ();
		mKeyboard.showKeyboard (activity);
		_currentAnswer = null;

		new Thread (new Runnable () {
			@Override
			public void run () {
				activity.runOnUiThread (new Runnable () {
					@Override
					public void run () {
						//Ensure visibility of value is under entering
						ensureVisibleCell (selRow, selCol);

						//Add next non alphanumeric char automatically
						if (isNewStart) {
							String nextVal = savedCrossword.getCellsValue (_startCellRow, _startCellCol);
							if (!isAplhaNumericValue (nextVal)) {
								insertText (nextVal);
							}
						}

						//Highlight the word have to be enter
						rebuildCrosswordTable ();

						//TEST
						showWinScreen ();
						//END TEST
					}
				});
			}
		}).start ();
	}

	private boolean isInputInHorizontalDirection () {
		boolean res = false;
		if (_availableAnswerDirections != null && _answerIndex >= 0 && _answerIndex < _availableAnswerDirections.size ()) {
			int currentDir = _availableAnswerDirections.get (_answerIndex);
			if (currentDir == CWCellType_Start_TopRight || currentDir == CWCellType_Start_FullRight ||
				currentDir == CWCellType_Start_BottomRight || currentDir == CWCellType_Start_LeftRight_Top ||
				currentDir == CWCellType_Start_LeftRight_Bottom) //Horizontal answer direction
			{
				res = true;
			}
		}
		return res;
	}

	private boolean isAplhaNumericValue (String value) {
		boolean res = false;
		if (value != null && value.length () > 0) {
			for (int offset = 0, len = value.length (); offset < len; ) {
				int codepoint = value.codePointAt (offset);
				if (Character.isLetterOrDigit (codepoint)) {
					res = true;
					break;
				}
				offset += Character.charCount (codepoint);
			}
		}
		return res;
	}

	private void fillLetterForCell (View cell, int row, int col, boolean highlighted, boolean currentCell) {
		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();

		boolean fillValue = false;
		String cellOrigValue = savedCrossword.getCellsValue (row, col);
		String cellValue = "";
		if (_areAnswersVisible || !isAplhaNumericValue (cellOrigValue)) {
			fillValue = true;
			cellValue = cellOrigValue;
		} else {
			//Get value from current answer if available
			if (_currentAnswer != null) {
				if (isInputInHorizontalDirection ()) { //Horizontal answer
					if (row == _startCellRow && col >= _startCellCol && col < (_startCellCol + _currentAnswer.length ())) {
						fillValue = true;
						int startPos = col - _startCellCol;
						cellValue = _currentAnswer.substring (startPos, startPos + 1);
					}
				} else { //Vertical answer
					if (col == _startCellCol && row >= _startCellRow && row < (_startCellRow + _currentAnswer.length ())) {
						fillValue = true;
						int startPos = row - _startCellRow;
						cellValue = _currentAnswer.substring (startPos, startPos + 1);
					}
				}
			}

			//Fill value from filled values
			if (!fillValue) {
				Pos pos = getPositionFromCoords (row, col);
				String value = _cellFilledValues.get (pos);
				if (value != null) {
					fillValue = true;
					cellValue = value;
				}
			}
		}

		CrosswordCell.fillLetter (cell, fillValue, cellValue, highlighted, currentCell);
	}

	private void fillCellsArrow (int cellType, int checkCellType, View cell, int row, int col,
								 boolean highlighted, boolean currentCell, boolean[] letterFilled) {
		if ((cellType & checkCellType) == checkCellType) {
			if (letterFilled[0] != true) {
				fillLetterForCell (cell, row, col, highlighted, currentCell);
				letterFilled[0] = true;
			}
			CrosswordCell.fillArrow (cell, checkCellType);
		}
	}

	private View buildCell (View cell, int row, int col) {
		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		int cellType = savedCrossword.getCellTypeInRow (row, col);

		boolean isHighlighted = false;
		boolean isCurrentCell = false;
		if (_answerIndex >= 0) {
			if (isInputInHorizontalDirection ()) {
				isHighlighted = row == _startCellRow && col >= _startCellCol && col < _startCellCol + _maxAnswerLength;
				isCurrentCell = row == _startCellRow && col == _startCellCol + (_currentAnswer == null ? 0 : _currentAnswer.length ());
			} else {
				isHighlighted = col == _startCellCol && row >= _startCellRow && row < _startCellRow + _maxAnswerLength;
				isCurrentCell = col == _startCellCol && row == _startCellRow + (_currentAnswer == null ? 0 : _currentAnswer.length ());
			}
		}

		switch (cellType) {
			case CWCellType_SingleQuestion:
				CrosswordCell.fillOneQuestion (cell, savedCrossword.getCellsQuestion (row, col, 0));
				break;
			case CWCellType_DoubleQuestion: {
				String qTop = savedCrossword.getCellsQuestion (row, col, 0);
				String qBottom = savedCrossword.getCellsQuestion (row, col, 1);
				CrosswordCell.fillTwoQuestion (cell, qTop, qBottom);
				break;
			}
			case CWCellType_Spacer:
				CrosswordCell.fillSpacer (cell);
				break;
			case CWCellType_Letter:
				fillLetterForCell (cell, row, col, isHighlighted, isCurrentCell);
				CrosswordCell.fillSeparator (cell, savedCrossword.getCellsSeparators (row, col));
				break;
			default: {
				boolean[] letterFilled = new boolean[] { false };
				fillCellsArrow (cellType, CWCellType_Start_TopDown_Right, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_TopDown_Left, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_TopDown_Bottom, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_TopRight, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_FullRight, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_BottomRight, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_LeftRight_Top, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				fillCellsArrow (cellType, CWCellType_Start_LeftRight_Bottom, cell, row, col, isHighlighted, isCurrentCell, letterFilled);
				CrosswordCell.fillSeparator (cell, savedCrossword.getCellsSeparators (row, col));
				break;
			}
		}

		return cell;
	}
	//endregion

	//region Implementation
	private void showSubscription () {
		SubscriptionManager.sharedInstance ().setPendingSubscriptionAlert (
			"You have to subscribe to the application to play more than one demo crossword! If you press yes, then we take you to our store screen to do that."
		);
		Navigation.findNavController (getView ()).navigateUp ();
	}

	private Pos getPositionFromCoords (int row, int col) {
		return new Pos (row, col);
	}

	private int getRowFromPosition (Pos pos) {
		return pos.getRow ();
	}

	private int getColFromPosition (Pos pos) {
		return pos.getCol ();
	}

	private void commitValidAnswer () {
		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();

		//Copy value into fill table
		int len = _currentAnswer == null ? 0 : _currentAnswer.length ();
		if (len > 0) {
			boolean answerCommitted = false;
			_currentAnswer = _currentAnswer.toLowerCase ();

			if (isInputInHorizontalDirection ()) { //Horizontal answer
				//Check answers validity
				boolean validAnswerFound = true;
				int answerLen = savedCrossword.width - _startCellCol;
				for (int col = _startCellCol, colEnd = savedCrossword.width; col < colEnd; ++col) {
					int cellType = savedCrossword.getCellTypeInRow (_startCellRow, col);
					if ((cellType & CWCellType_HasValue) == 0) { //We reach the end of this value
						answerLen = col - _startCellCol;
						break;
					}

					if (_currentAnswer.length () <= col - _startCellCol) {
						validAnswerFound = false;
						break;
					}

					String cellValue = savedCrossword.getCellsValue (_startCellRow, col);
					if (cellValue != null && cellValue.length () > 0 &&
						_currentAnswer.charAt (col - _startCellCol) != cellValue.charAt (0)) //We found an invalid character
					{
						validAnswerFound = false;
						break;
					}
				}

				if (answerLen == len && validAnswerFound) { //We have a valid answer
					//Send netlog
					if (_cellFilledValues.size () == 0) { //First word committed
						NetLogger.logEvent ("Crossword_FirstFilled");
					}

					//Copy values to grid
					for (int i = 0; i < len; ++i) {
						String val = String.format ("%C", _currentAnswer.charAt (i));
						Pos path = getPositionFromCoords (_startCellRow, _startCellCol + i);
						_cellFilledValues.put (path, val);
					}

					//Save filled values
					savedCrossword.saveFilledValues (_cellFilledValues);

					//Sign committed result
					answerCommitted = true;
				}
			} else { //Vertical answer
				//Check answers validity
				boolean validAnswerFound = true;
				int answerLen = savedCrossword.height - _startCellRow;
				for (int row = _startCellRow, rowEnd = savedCrossword.height; row < rowEnd; ++row) {
					int cellType = savedCrossword.getCellTypeInRow (row, _startCellCol);
					if ((cellType & CWCellType_HasValue) == 0) { //We reach the end of this value
						answerLen = row - _startCellRow;
						break;
					}

					if (_currentAnswer.length () <= row - _startCellRow) {
						validAnswerFound = false;
						break;
					}

					String cellValue = savedCrossword.getCellsValue (row, _startCellCol);
					if (cellValue != null && cellValue.length () > 0 &&
						_currentAnswer.charAt (row - _startCellRow) != cellValue.charAt (0)) //We found an invalid character
					{
						validAnswerFound = false;
						break;
					}
				}

				if (answerLen == len && validAnswerFound) { //We have a valid answer
					//Send netlog
					if (_cellFilledValues.size () == 0) { //First word committed
						NetLogger.logEvent ("Crossword_FirstFilled");
					}

					//Copy values to grid
					for (int i = 0; i < len; ++i) {
						String val = String.format ("%C", _currentAnswer.charAt (i));
						Pos path = getPositionFromCoords (_startCellRow + i, _startCellCol);
						_cellFilledValues.put (path, val);
					}

					//Save filled values
					savedCrossword.saveFilledValues (_cellFilledValues);

					//Sign committed result
					answerCommitted = true;
				}
			}

			if (answerCommitted) {
				//Determine filled state
				FillRatio fillRatio = calculateFillRatio ();
				_isFilled = fillRatio.isFilled;

				//Go to win, if all field filled
				if (_isFilled) {
					showWinScreen ();
				}
			} else {
				++_failCount;
			}
		}
	}

	private void resetInput () {
		_currentAnswer = null;
		_canBecameFirstResponder = false;
		_maxAnswerLength = 0;
		_startCellCol = -1;
		_startCellRow = -1;
		_availableAnswerDirections = null;
		_answerIndex = -1;

		mKeyboard.hideKeyboard (getActivity ());
	}

	private void resetStatistics () {
		_failCount = 0;
		_hintCount = 0;
		_startTime = Calendar.getInstance ();
		_isFilled = false;
		_starCount = 0;
	}

	private static class FillRatio {
		double fillRatio = 0;
		boolean isFilled = false;
	}

	private FillRatio calculateFillRatio () {
		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();

		int valueCellCount = 0;
		int filledCellCount = 0;

		for (int row = 0, rowEnd = savedCrossword.height; row < rowEnd; ++row) {
			for (int col = 0, colEnd = savedCrossword.width; col < colEnd; ++col) {
				int cellType = savedCrossword.getCellTypeInRow (row, col);
				if ((cellType & CWCellType_HasValue) != 0) {
					++valueCellCount;

					Pos pos = getPositionFromCoords (row, col);
					String val = _cellFilledValues.get (pos);
					if (val != null && val.length () > 0) {
						++filledCellCount;
					}
				}
			}
		}

		FillRatio res = new FillRatio ();

		res.fillRatio = valueCellCount > 0 ? (double) filledCellCount / (double) valueCellCount : 1.0;
		res.isFilled = filledCellCount == valueCellCount;
		if (res.isFilled) {
			res.fillRatio = 1.0;
		}

		return res;
	}

	private void mergeStatistics () {
		FillRatio fillRatio = calculateFillRatio ();
		saveStatistics (fillRatio.fillRatio, fillRatio.isFilled);
	}

	private void saveStatistics (double fillRatio, boolean isFilled) {
		long duration = (Calendar.getInstance ().getTimeInMillis () - _startTime.getTimeInMillis ()) / 1000;

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		savedCrossword.mergeStatistics (_failCount, _hintCount, fillRatio, isFilled, (int) duration);

		int statOffset = savedCrossword.loadStatisticsOffset ();
		if (statOffset < 0) {
			String packageKey = mViewModel.getCurrentPackage ().getPackageKey ();
			int maxStatCount = PackageManager.sharedInstance ().getMaxStatCountOfCWSet (packageKey);
			savedCrossword.saveStatisticsOffset (maxStatCount-1);
		}

		resetStatistics ();
	}

	private int calculateStarCount (Statistics stats) {
		if (stats.failCount > 9 || stats.hintCount > 9 || stats.fillDuration > 20 * 60) { //0 star
			return 0;
		}

		if (stats.failCount > 6 || stats.hintCount > 6 || stats.fillDuration > 15 * 60) { //1 star
			return 1;
		}

		if (stats.failCount > 3 || stats.hintCount > 3 || stats.fillDuration > 12 * 60) { //2 star
			return 2;
		}

		return 3;
	}

	private void showWinView () {
		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		ArrayList<Statistics> stats = savedCrossword.loadStatistics ();
		if (stats == null || stats.size () <= 0) {
			return;
		}

		Statistics currentStat = stats.get (stats.size () - 1);
		if (currentStat == null) {
			return;
		}

		//Fill statistics view
		FragmentActivity activity = getActivity ();

		Calendar date = Calendar.getInstance ();
		date.setTimeZone (new SimpleTimeZone (0, "UTC"));
		date.setTimeInMillis (currentStat.fillDuration * 1000);
		SimpleDateFormat dateFormatter = new SimpleDateFormat ("HH:mm:ss");
		dateFormatter.setTimeZone (date.getTimeZone ());
		String formattedDate = dateFormatter.format (date.getTime ());

		TextView winTimeLabel = activity.findViewById (R.id.cwview_win_time_label);
		winTimeLabel.setText (String.format ("Time: %s", formattedDate));

		TextView winHintCountLabel = activity.findViewById (R.id.cwview_win_hint_count_label);
		winHintCountLabel.setText (String.format ("Hint show count: %d", currentStat.hintCount));

		TextView winWordCountLabel = activity.findViewById (R.id.cwview_win_word_count_label);
		winWordCountLabel.setText (String.format ("Word count: %d", savedCrossword.words == null ? 0 : savedCrossword.words.size ()));

		TextView winFailCountLabel = activity.findViewById (R.id.cwview_win_fail_count_label);
		winFailCountLabel.setText (String.format ("Fail count: %d", currentStat.failCount));

		//Handle stars
		_starCount = calculateStarCount (currentStat);

		ImageView starView = activity.findViewById (R.id.cwview_win_star1);
		if (_starCount > 0) {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.star));
		} else {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.gray_star));
		}

		starView = activity.findViewById (R.id.cwview_win_star2);
		if (_starCount > 1) {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.star));
		} else {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.gray_star));
		}

		starView = activity.findViewById (R.id.cwview_win_star3);
		if (_starCount > 2) {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.star));
		} else {
			starView.setImageDrawable (activity.getResources ().getDrawable (R.drawable.gray_star));
		}

		//Handle multi level game
		TextView winMessageLabel = activity.findViewById (R.id.cwview_win_message_label);
		Button winCloseButton = activity.findViewById (R.id.cwview_win_close_button);

		if (mViewModel.getIsMultiLevelGame ()) {
			if (_starCount < 3) { //Fail
				winMessageLabel.setText ("You can do this better!\nTry again!");
				winCloseButton.setText ("Try again");
			} else { //Go to the next level, or end of all levels
				Package currentPackage = mViewModel.getCurrentPackage ();
				ArrayList<SavedCrossword> allSavedCrossword = mViewModel.getAllSavedCrossword ();
				boolean isSubscribed = SubscriptionManager.sharedInstance ().isSubscribed ();
				if (isSubscribed && currentPackage.state != null && currentPackage.state.filledLevel < currentPackage.state.levelCount) {
					currentPackage.state.filledLevel += 1;
					currentPackage.state.filledWordCount += savedCrossword.words == null ? 0 : savedCrossword.words.size ();
				}

				int nextCWIdx = mViewModel.getCurrentCrosswordIndex () + 1;
				boolean hasMoreLevel = nextCWIdx < (allSavedCrossword == null ? 0 : allSavedCrossword.size ());

				if (hasMoreLevel) {
					if (isSubscribed && currentPackage.state != null) {
						currentPackage.state.crosswordName = allSavedCrossword.get (nextCWIdx).name;
					}

					winMessageLabel.setText ("You earn 3 stars!\nGo to the next level!");
					winCloseButton.setText ("Next Level");
				} else {
					winMessageLabel.setText ("You filled all levels!");
					winCloseButton.setText ("OK");
				}

				if (isSubscribed) {
					PackageManager.sharedInstance ().savePackageState (currentPackage);
				}
			}
		} else { //Single level game
			if (_starCount < 3) {
				winMessageLabel.setText ("You can do this better!\nTry again!");
				winCloseButton.setText ("Try again");
			} else {
				winMessageLabel.setText ("You earn 3 stars!");
				winCloseButton.setText ("OK");
			}
		}

		//Show statistics view
		LinearLayout layout = activity.findViewById (R.id.cwview_winscreen);
		layout.setVisibility (View.VISIBLE);
	}

	private void showWinScreen () {
		_isWinScreenOn = true;
		lockOrientation ();

		final FragmentActivity activity = getActivity ();

		resetInput ();
		mKeyboard.hideKeyboard (activity);

		//Save statistics
		saveStatistics (1.0, true);

		//Send netlog
		NetLogger.logEvent ("Crossword_Win");

		//Start emitters
		//TODO: ...

		final Calendar[] start = {null};
		_timerWin = new Timer ();
		_timerWin.schedule (new TimerTask () {
			@Override
			public void run () {
				double duration = 2.0;
				if (start[0] == null) {
					start[0] = Calendar.getInstance ();
				}

				long dT = (Calendar.getInstance ().getTimeInMillis () - _startTime.getTimeInMillis ()) / 1000; //Elapsed time: [sec]

				//The function of the fireball is: y=x*x
				//TODO: ...


				//End of animation
				if (dT >= duration * 1.005) {
//					[self->_emitterWin[0] stop];
//					[self->_emitterWin[1] stop];
//
//					[self->_emitterWin[2] startFireWorks:[self view] pt:pt0];
//					[self->_emitterWin[3] startFireWorks:[self view] pt:pt1];

					_timerWin.cancel ();
					_timerWin.purge ();

					activity.runOnUiThread (new Runnable () {
						@Override
						public void run () {
							showWinView ();
						}
					});
				}
			}
		}, 50, 50);
	}

	private void addAvailableInputDirection (int cellType, int checkCellType) {
		if ((cellType & checkCellType) == checkCellType) {
			_availableAnswerDirections.add (checkCellType);
		}
	}

	private void ensureVisibleCell (int row, int col) {
		int pixels = getCellSizeInPixels ();
		int scrollX = Math.max (col, 0) * pixels;
		int scrollY = Math.max (row, 0) * pixels;

		TwoDScrollView scrollView = getActivity ().findViewById (R.id.cwview_scroll);
		scrollView.ensureVisibleRect (scrollX, scrollY, pixels, pixels);
	}
	//endregion

	//region Key input
	private boolean hasText () {
		return _currentAnswer != null && _currentAnswer.length () > 0;
	}

	public void deleteBackward () {
		//Alter answer
		int len = _currentAnswer == null ? 0 : _currentAnswer.length ();
		if (len > 1) {
			_currentAnswer = _currentAnswer.substring (0, len - 1);
		} else if (len == 1) {
			_currentAnswer = null;
		}

		//Ensure visibility of next char to enter
		if (isInputInHorizontalDirection ()) {
			ensureVisibleCell (_startCellRow, _startCellCol + (_currentAnswer == null ? 0 : _currentAnswer.length ()));
		} else {
			ensureVisibleCell (_startCellRow + (_currentAnswer == null ? 0 : _currentAnswer.length ()), _startCellCol);
		}

		//Fill grid
		rebuildCrosswordTable ();
	}

	public void insertText (String text) {
		//Handle input
		if (text.equals ("\n")) { //Handle press of return (done button)
			commitValidAnswer ();
			resetInput ();
		} else { //Handle normal keys
			//Check available length
			if (_currentAnswer != null && _currentAnswer.length () >= _maxAnswerLength) { //Allow only entering of chars, when enough space remaining
				return;
			}

			//Alter answer
			int len = _currentAnswer == null ? 0 : _currentAnswer.length ();
			if (len > 0) {
				_currentAnswer += text;
			} else {
				_currentAnswer = text;
			}

			//Calculate next cell's coords
			boolean isHorizontalInput = isInputInHorizontalDirection ();
			int nextCol = 0;
			int nextRow = 0;
			if (isHorizontalInput) {
				nextRow = _startCellRow;
				nextCol = _startCellCol + _currentAnswer.length ();
			} else {
				nextRow = _startCellRow + _currentAnswer.length ();
				nextCol = _startCellCol;
			}

			//Ensure visibility of next char
			SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
			if (isHorizontalInput) {
				if (nextCol < savedCrossword.width) {
					ensureVisibleCell (_startCellRow, nextCol);
				}
			} else {
				if (nextRow < savedCrossword.height) {
					ensureVisibleCell (nextRow, _startCellCol);
				}
			}

			//Add next non alphanumeric char automatically
			String nextVal = savedCrossword.getCellsValue (nextRow, nextCol);
			if (nextVal != null && !isAplhaNumericValue (nextVal)) {
				insertText (nextVal);
			}
		}

		//Fill grid
		rebuildCrosswordTable ();
	}

	public void dismissKeyboard () {
		commitValidAnswer ();
		resetInput ();
		mKeyboard.hideKeyboard (getActivity ());
		rebuildCrosswordTable ();
	}
	//endregion
}
