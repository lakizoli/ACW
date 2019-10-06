package com.zapp.acw.ui.main;

import android.graphics.Color;
import android.graphics.Typeface;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.zapp.acw.R;

import androidx.appcompat.widget.AppCompatTextView;
import androidx.core.content.res.ResourcesCompat;
import androidx.core.widget.TextViewCompat;

import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_BottomRight;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_FullRight;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_LeftRight_Bottom;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_LeftRight_Top;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_TopDown_Bottom;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_TopDown_Left;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_TopDown_Right;
import static com.zapp.acw.ui.main.CrosswordFragment.CWCellType_Start_TopRight;

public class CrosswordCell {
	public static void fillOneQuestion (View cell, String question) {
		clearContent (cell);

		TextView fullLabel = getFullLabel (cell);
		fullLabel.setBackgroundColor (cell.getResources ().getColor (R.color.colorLightBlueBack));
		fullLabel.setTextColor (Color.BLACK);

		fullLabel.setText (question);
		setQuestionFont (fullLabel);

		setHiddensForFullHidden (cell, false, true, true);
	}

	public static void fillTwoQuestion (View cell, String questionTop, String questionBottom) {
		clearContent (cell);

		TextView topLabel = getTopLabel (cell);
		TextView bottomLabel = getBottomLabel (cell);

		topLabel.setBackgroundColor (cell.getResources ().getColor (R.color.colorLightBlueBack));
		bottomLabel.setBackgroundColor (cell.getResources ().getColor (R.color.colorLightBlueBack));

		topLabel.setTextColor (Color.BLACK);
		bottomLabel.setTextColor (Color.BLACK);

		topLabel.setText (questionTop);
		bottomLabel.setText (questionBottom);

		setQuestionFont (topLabel);
		setQuestionFont (bottomLabel);

		setHiddensForFullHidden (cell, true, false, false);
	}

	public static void fillSpacer (View cell) {
		clearContent (cell);
	}

	public static void fillLetter (View cell, boolean showValue, String value, boolean highlighted, boolean currentCell) {
		clearContent (cell);

		TextView fullLabel = getFullLabel (cell);

		if (highlighted) {
			if (currentCell) {
				fullLabel.setBackgroundColor (cell.getResources ().getColor (R.color.highlightedCurrentCell));
			} else {
				fullLabel.setBackgroundColor (cell.getResources ().getColor (R.color.highlightedCell));
			}
			fullLabel.setTextColor (cell.getResources ().getColor (R.color.highlightedCellText));
		} else {
			fullLabel.setBackgroundColor (Color.WHITE);
			fullLabel.setTextColor (Color.BLACK);
		}

		setHiddensForFullHidden (cell,false, true, true);
		setValueFont (fullLabel);

		if (showValue) {
			fullLabel.setText (value.toUpperCase ());
		}
	}

	public static void fillArrow (View cell, int cellType) {
		switch (cellType) {
			case CWCellType_Start_TopDown_Right:{
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_topright_down);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_TopDown_Left:{
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_topleft_down);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_TopDown_Bottom: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_bottom_down);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_TopRight: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_topright);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_FullRight: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_right);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_BottomRight: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_bottomright);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_LeftRight_Top: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_leftright_top);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			case CWCellType_Start_LeftRight_Bottom: {
				ImageView imageView = cell.findViewById (R.id.cwcell_arrow_leftright_bottom);
				imageView.setVisibility (View.VISIBLE);
				break;
			}
			default:
				break;
		}
	}

	public static void fillSeparator (View cell, int separators) {
		float scale = cell.getContext().getResources().getDisplayMetrics().density;

		TextView textView = cell.findViewById (R.id.cwcell_value);
		RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) textView.getLayoutParams ();

		if ((separators & CWCellSeparator_Left) == CWCellSeparator_Left) {
			layoutParams.leftMargin = (int) (2 * scale);
		}

		if ((separators & CWCellSeparator_Top) == CWCellSeparator_Top) {
			layoutParams.topMargin = (int) (2 * scale);
		}

		if ((separators & CWCellSeparator_Right) == CWCellSeparator_Right) {
			layoutParams.rightMargin = (int) (2 * scale);
		}

		if ((separators & CWCellSeparator_Bottom) == CWCellSeparator_Bottom) {
			layoutParams.bottomMargin = (int) (2 * scale);
		}
	}

	//region Implementation
	private static final int CWCellSeparator_None		= 0x0000;
	private static final int CWCellSeparator_Left		= 0x0001;
	private static final int CWCellSeparator_Top		= 0x0002;
	private static final int CWCellSeparator_Right		= 0x0004;
	private static final int CWCellSeparator_Bottom		= 0x0008;
	private static final int CWCellSeparator_All		= 0x000F;

	private static TextView getFullLabel (View cell) {
		return cell.findViewById (R.id.cwcell_value);
	}

	private static TextView getTopLabel (View cell) {
		return cell.findViewById (R.id.cwcell_top_question);
	}

	private static TextView getBottomLabel (View cell) {
		return cell.findViewById (R.id.cwcell_bottom_question);
	}

	private static void setHiddensForFullHidden (View cell, boolean fullHidden, boolean topHidden, boolean bottomHidden) {
		getFullLabel (cell).setVisibility (fullHidden ? View.INVISIBLE : View.VISIBLE);
		getTopLabel (cell).setVisibility (topHidden ? View.INVISIBLE : View.VISIBLE);
		getBottomLabel (cell).setVisibility (bottomHidden ? View.INVISIBLE : View.VISIBLE);
	}

	private static void clearContent (View cell) {
		//Set all content to hidden
		setHiddensForFullHidden (cell,true, true, true);

		//Clear arrows and separators
		ImageView imageView = cell.findViewById (R.id.cwcell_arrow_bottom_down);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_topright);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_right);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_bottomright);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_leftright_top);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_leftright_bottom);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_topleft_down);
		imageView.setVisibility (View.INVISIBLE);

		imageView = cell.findViewById (R.id.cwcell_arrow_topright_down);
		imageView.setVisibility (View.INVISIBLE);

		//Clear text
		TextView textView = cell.findViewById (R.id.cwcell_value);
		textView.setText ("");
	}

	private static void setQuestionFont (TextView textView) {
		Typeface typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD);
		textView.setTypeface (typeface);
		TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration (textView, 3, 14, 1, TypedValue.COMPLEX_UNIT_SP);
	}

	private static void setValueFont (TextView textView) {
		Typeface typeface = ResourcesCompat.getFont (textView.getContext (), R.font.bradley_hand);
		textView.setTypeface (typeface);
		TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration (textView, 3, 26, 1, TypedValue.COMPLEX_UNIT_SP);
	}

	//endregion
}
