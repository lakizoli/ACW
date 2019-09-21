package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TableLayout;
import android.widget.TableRow;

import com.zapp.acw.R;
import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.Pos;
import com.zapp.acw.bll.SavedCrossword;
import com.zapp.acw.bll.SubscriptionManager;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Timer;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;

public class CrosswordFragment extends Fragment implements Toolbar.OnMenuItemClickListener {
	private CrosswordViewModel mViewModel;

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
	Timer _timerWin;
//	EmitterEffect *_emitterWin[4];
	int _starCount = 0;

	public static CrosswordFragment newInstance () {
		return new CrosswordFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.crossword_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mViewModel = ViewModelProviders.of (this).get (CrosswordViewModel.class);

		final FragmentActivity activity = getActivity ();

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.cwview_toolbar);
		toolbar.inflateMenu (R.menu.cwview_menu);
		toolbar.setOnMenuItemClickListener (this);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				Navigation.findNavController (getView ()).navigateUp ();
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				Navigation.findNavController (getView ()).navigateUp ();
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		//Init view model
		mViewModel.init (getArguments ());

		//Build crossword table
		buildCrosswordTable (activity);
	}

	@Override
	public boolean onMenuItemClick (MenuItem item) {
		switch (item.getItemId ()) {
			case R.id.cwview_reset:
				return true;
			case R.id.cwview_hint:
				return true;
			default:
				break;
		}
		return false;
	}

	//region Build crossword table
	private static final int CWCellType_Unknown					= 0x0000;
	private static final int CWCellType_SingleQuestion			= 0x0001;
	private static final int CWCellType_DoubleQuestion			= 0x0002;
	private static final int CWCellType_Spacer					= 0x0004;
	private static final int CWCellType_Letter					= 0x0008;
	private static final int CWCellType_Start_TopDown_Right		= 0x0010;
	private static final int CWCellType_Start_TopDown_Left		= 0x0020;
	private static final int CWCellType_Start_TopDown_Bottom	= 0x0040;
	private static final int CWCellType_Start_TopRight			= 0x0080;
	private static final int CWCellType_Start_FullRight			= 0x0100;
	private static final int CWCellType_Start_BottomRight		= 0x0200;
	private static final int CWCellType_Start_LeftRight_Top		= 0x0400;
	private static final int CWCellType_Start_LeftRight_Bottom	= 0x0800;
	private static final int CWCellType_HasValue				= 0x0FF8;

	private static final int CWCellSeparator_None		= 0x0000;
	private static final int CWCellSeparator_Left		= 0x0001;
	private static final int CWCellSeparator_Top		= 0x0002;
	private static final int CWCellSeparator_Right		= 0x0004;
	private static final int CWCellSeparator_Bottom		= 0x0008;
	private static final int CWCellSeparator_All		= 0x000F;

	private void buildCrosswordTable (FragmentActivity activity) {
		TableLayout table = activity.findViewById (R.id.cw_table);

		final float scale = getContext().getResources().getDisplayMetrics().density;
		int pixels = Math.round (50.0f * scale + 0.5f);

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		for (int row = 0; row < savedCrossword.height;++row) {
			TableRow tableRow = new TableRow (activity);
			table.addView (tableRow);

			tableRow.setLayoutParams (new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));

			for (int col = 0; col < savedCrossword.width;++col) {
				View cell = buildCell (activity, row, col);
				tableRow.addView (cell);

				cell.requestLayout ();

				cell.getLayoutParams ().width = pixels;
				cell.getLayoutParams ().height = pixels;
				cell.setBackgroundColor ((col % 2 == 0 && row % 2 == 0) || (col % 2 == 1 && row % 2 == 1) ? 0xFFAA0000 : 0xFF00AA00);
			}
		}
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

	private View buildCell (FragmentActivity activity, int row, int col) {
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
//				[cell fillOneQuestion:[_savedCrossword getCellsQuestion:row col:col questionIndex:0] scale:[_crosswordLayout scaleFactor]];
				break;
			case CWCellType_DoubleQuestion: {
//				NSString* qTop = [_savedCrossword getCellsQuestion:row col:col questionIndex:0];
//				NSString* qBottom = [_savedCrossword getCellsQuestion:row col:col questionIndex:1];
//				[cell fillTwoQuestion:qTop questionBottom:qBottom scale:[_crosswordLayout scaleFactor]];
				break;
			}
			case CWCellType_Spacer:
//				[cell fillSpacer];
				break;
			case CWCellType_Letter:
//				[self fillLetterForCell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell];
//				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col] scale:[_crosswordLayout scaleFactor]];
//				break;
			default: {
				boolean letterFilled = false;
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Right cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Left cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Bottom cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopRight cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_FullRight cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_BottomRight cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Top cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Bottom cell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell letterFilled:&letterFilled];
//				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col] scale:[_crosswordLayout scaleFactor]];
				break;
			}
		}

		return new View (activity);
	}
	//endregion

	//region Implementation
	private void showSubscription () {
		SubscriptionManager.sharedInstance ().showSubscriptionAlert (getActivity (), getView (),
			"You have to subscribe to the application to play more than one demo crossword! If you press yes, then we take you to our store screen to do that."
		);
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
						String val = String.format ("%c", _currentAnswer.charAt (i));
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
						String val = String.format ("%c", _currentAnswer.charAt (i));
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
//				//Determine filled state
//				[self calculateFillRatio:&_isFilled];
//
//				//Go to win, if all field filled
//				if (_isFilled) {
//					[self showWinScreen];
//				}
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

//		[self resignFirstResponder];
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
//				uint32_t cellType = [_savedCrossword getCellTypeInRow:row col:col];
//				if ((cellType & CWCellType_HasValue) != 0) {
//					++valueCellCount;
//
//					NSIndexPath *indexPath = [self getIndexPathForRow:row col:col];
//					NSString *val = [_cellFilledValues objectForKey:indexPath];
//					if ([val length] > 0) {
//						++filledCellCount;
//					}
//				}
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

	//endregion
}
