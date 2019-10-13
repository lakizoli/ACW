package com.zapp.acw.bll;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.Keep;

@Keep
public final class Deck implements Parcelable {
	public long deckID = 0;
	public String name;
	public String packagePath;

	public Deck () {
	}

	//region Parcelable implementation
	public static final Parcelable.Creator<Deck> CREATOR = new Parcelable.Creator<Deck> () {
		public Deck createFromParcel (Parcel source) {
			return new Deck (source);
		}

		public Deck[] newArray (int size) {
			return new Deck[size];
		}
	};

	public Deck (Parcel parcel) {
		deckID = parcel.readLong ();
		name = parcel.readString ();
		packagePath = parcel.readString ();
	}

	@Override
	public int describeContents () {
		return hashCode ();
	}

	@Override
	public void writeToParcel (Parcel dest, int flags) {
		dest.writeLong (deckID);
		dest.writeString (name);
		dest.writeString (packagePath);
	}
	//endregion
}
