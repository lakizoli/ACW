package com.zapp.acw.ui.main;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;
import android.text.Html;
import android.text.Spanned;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.GeneratorInfo;
import com.zapp.acw.bll.Package;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.StringRes;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

public class GenFragment extends Fragment implements Toolbar.OnMenuItemClickListener {

	private GenViewModel mViewModel;
	private ProgressView mProgressView;
	private boolean mHaveToDismissParent = false;

	public static GenFragment newInstance () {
		return new GenFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.gen_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (GenViewModel.class);

		final FragmentActivity activity = getActivity ();

		final ProgressBar progressGen = activity.findViewById (R.id.gen_progress);
		progressGen.setVisibility (View.VISIBLE);

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action) {
					case GenViewModel.GENERATION_ENDED:
						//Dismiss view with parent also
						dismissView ();
						break;
					default:
						break;
				}
			}
		});

		mViewModel.getLabelIndex ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer index) {
				mProgressView.setLabel (mProgressView.getString (R.string.generating_crossword) + " (" + index + ")");
			}
		});

		mViewModel.getProgress ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer progress) {
				mProgressView.setProgress (progress);
			}
		});

		mViewModel.getGeneratorInfo ().observe (getViewLifecycleOwner (), new Observer<GeneratorInfo> () {
			@Override
			public void onChanged (GeneratorInfo generatorInfo) {
				progressGen.setVisibility (View.INVISIBLE);

				//Set question chooser
				final RecyclerView rvQuestion = activity.findViewById (R.id.question_chooser);

				GenAdapter adapter = new GenAdapter (generatorInfo, mViewModel.getQuestionFieldIndex (), new GenAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (int position, Field field) {
						mViewModel.setQuestionFieldIndex (position);

						TextView textView = activity.findViewById (R.id.text_question_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, R.string.question_field, fieldValue);
					}
				}, new GenAdapter.OnInitialSelectionListener () {
					@Override
					public void onInitialSelection (int position, Field field) {
						mViewModel.setQuestionFieldIndex (position);

						TextView textView = activity.findViewById (R.id.text_question_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, R.string.question_field, fieldValue);
					}
				});

				rvQuestion.setAdapter (adapter);
				rvQuestion.setLayoutManager (new LinearLayoutManager (activity));

				//Set solution chooser
				final RecyclerView rvSolution = activity.findViewById (R.id.solution_chooser);

				adapter = new GenAdapter (generatorInfo, mViewModel.getSolutionFieldIndex (), new GenAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (int position, Field field) {
						mViewModel.setSolutionFieldIndex (position);

						TextView textView = activity.findViewById (R.id.text_solution_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, R.string.solution_field, fieldValue);
					}
				}, new GenAdapter.OnInitialSelectionListener () {
					@Override
					public void onInitialSelection (int position, Field field) {
						mViewModel.setSolutionFieldIndex (position);

						TextView textView = activity.findViewById (R.id.text_solution_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, R.string.solution_field, fieldValue);
					}
				});

				rvSolution.setAdapter (adapter);
				rvSolution.setLayoutManager (new LinearLayoutManager (activity));
			}
		});

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.gen_toolbar);
		toolbar.inflateMenu (R.menu.gen_menu);
		toolbar.setOnMenuItemClickListener (this);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				dismissView ();
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				dismissView ();
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		//Init progress view
		mProgressView = new ProgressView (activity, R.id.gen_progress_view, R.id.gen_text_view_progress, R.id.gen_progress_bar, R.id.gen_button_progress);
		mProgressView.setVisibility (View.INVISIBLE);
		unlockOrientation ();

		//Init view model
		Bundle args = getArguments ();
		mHaveToDismissParent = false;
		Package pack = null;
		if (args != null) {
			pack = args.getParcelable ("package");
			if (args.getBoolean ("moveChooseInsteadOfDismiss")) {
				mHaveToDismissParent = true;
			}
		}

		mViewModel.startCollectGeneratorInfo (pack);
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_done:
				//Disable toolbar
				final FragmentActivity activity = getActivity ();
				Toolbar toolbar = activity.findViewById (R.id.gen_toolbar);
				toolbar.setEnabled (false);

				//Show progress
				mProgressView.setButtonText (R.string.cancel);
				mProgressView.setLabel (R.string.generating_crossword);
				mProgressView.setProgress (0);

				mProgressView.setOnButtonPressed (new Runnable () {
					@Override
					public void run () {
						mViewModel.cancelGeneration ();
					}
				});

				mProgressView.setVisibility (View.VISIBLE);
				lockOrientation ();

				//Generate crosswords
				mViewModel.startGeneration ();
				return true;
			default:
				break;
		}
		return false;
	}

	private void lockOrientation () {
		int orientation = getActivity ().getRequestedOrientation ();
		int rotation = ((WindowManager) getActivity ().getSystemService (Context.WINDOW_SERVICE)).getDefaultDisplay ().getRotation ();
		switch (rotation) {
			case Surface.ROTATION_0:
				orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
				break;
			case Surface.ROTATION_90:
				orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
				break;
			case Surface.ROTATION_180:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
				break;
			default:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
				break;
		}

		getActivity ().setRequestedOrientation (orientation);
	}

	private void unlockOrientation () {
		getActivity ().setRequestedOrientation (ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
	}

	private void dismissView () {
		unlockOrientation ();
		if (mHaveToDismissParent) {
			Navigation.findNavController (getView ()).navigate (R.id.ShowChooseCW);
		} else {
			Navigation.findNavController (getView ()).navigateUp ();
		}
	}

	private void updatePickerLabel (TextView label, @StringRes int text, String exampleContent) {
		if (exampleContent == null) {
			label.setText (text);
			return;
		}

		String example = String.format (label.getResources ().getString (R.string.example_format), exampleContent);
		String htmlContentText = label.getResources ().getString (text);

		Spanned content;
		if (Build.VERSION.SDK_INT >= 24) {
			content = Html.fromHtml (String.format ("<span>%s</span> <i><font color='#AAAAAA'>%s</font></i>", htmlContentText, example), Html.FROM_HTML_MODE_COMPACT);
		} else {
			content = Html.fromHtml (String.format ("<span>%s</span> <i><font color='#AAAAAA'>%s</font></i>", htmlContentText, example));
		}
		label.setText (content);
	}
}
