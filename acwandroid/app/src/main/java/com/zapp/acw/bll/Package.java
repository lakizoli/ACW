package com.zapp.acw.bll;

import android.os.Parcel;
import android.os.Parcelable;

import com.zapp.acw.FileUtils;

import java.util.ArrayList;
import java.util.Arrays;

import androidx.annotation.Keep;

@Keep
public final class Package implements Parcelable {
	public String path;
	public String name;
	public ArrayList<Deck> decks;
	public GameState state;

	public Package () {
	}

	public String getPackageKey () {
		return FileUtils.getFileName (path);
	}

	//region Parcelable implementation
	public static final Parcelable.Creator<Package> CREATOR = new Parcelable.Creator<Package> () {
		public Package createFromParcel (Parcel source) {
			return new Package (source);
		}

		public Package[] newArray (int size) {
			return new Package[size];
		}
	};

	public Package (Parcel parcel) {
		path = parcel.readString ();
		name = parcel.readString ();

		Deck[] arr = (Deck[]) parcel.readParcelableArray (Deck.class.getClassLoader ());
		if (arr != null) {
			decks = new ArrayList<> (Arrays.asList (arr));
		}

		state = parcel.readParcelable (GameState.class.getClassLoader ());
	}

	@Override
	public int describeContents () {
		return hashCode ();
	}

	@Override
	public void writeToParcel (Parcel dest, int flags) {
		dest.writeString (path);
		dest.writeString (name);
		if (decks != null && decks.size () > 0) {
			dest.writeParcelableArray (decks.toArray (new Deck[0]), flags);
		} else {
			dest.writeParcelableArray (null, flags);
		}
		dest.writeParcelable (state, flags);
	}
	//endregion
}
