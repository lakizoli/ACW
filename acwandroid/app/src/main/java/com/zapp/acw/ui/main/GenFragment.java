package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.GeneratorInfo;
import com.zapp.acw.bll.Package;

public class GenFragment extends Fragment implements Toolbar.OnMenuItemClickListener {

	private GenViewModel mViewModel;

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

		mViewModel.getGeneratorInfo ().observe (getViewLifecycleOwner (), new Observer<GeneratorInfo> () {
			@Override
			public void onChanged (GeneratorInfo generatorInfo) {
				//Set question chooser
				final RecyclerView rvQuestion = activity.findViewById (R.id.question_chooser);

				GenAdapter adapter = new GenAdapter (generatorInfo, new GenAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (Field field) {
						TextView textView = activity.findViewById (R.id.text_question_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, "Question field:", fieldValue);
					}
				});

				rvQuestion.setAdapter(adapter);
				rvQuestion.setLayoutManager(new LinearLayoutManager (activity));

				//Set solution chooser
				final RecyclerView rvSolution = activity.findViewById (R.id.solution_chooser);

				adapter = new GenAdapter (generatorInfo, new GenAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (Field field) {
						TextView textView = activity.findViewById (R.id.text_solution_value);
						String fieldValue = mViewModel.getFieldValue (field);
						updatePickerLabel (textView, "Solution field:", fieldValue);
					}
				});

				rvSolution.setAdapter(adapter);
				rvSolution.setLayoutManager(new LinearLayoutManager (activity));
			}
		});

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.toolbar);
		toolbar.inflateMenu (R.menu.gen_menu);
		toolbar.setOnMenuItemClickListener (this);

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				//...Nothing to do here...
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		//Init view model
		Bundle args = getArguments ();
		Package pack = null;
		if (args != null) {
			pack = args.getParcelable ("package");
		}

		mViewModel.startCollectGeneratorInfo (pack);
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_done:
				//TODO: Navigation.findNavController (getView ()).navigate (R.id.ShowGen);
				return true;
			default:
				break;
		}
		return false;
	}

	private void updatePickerLabel (TextView label, String text, String exampleContent) {
		if (exampleContent == null) {
			label.setText (text);
			return;
		}

		String example = String.format ("(e.g.: \"%s\")", exampleContent);
		String content = String.format ("%s %s", text, example);
		label.setText (content);
	}
}
