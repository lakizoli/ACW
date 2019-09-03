package com.zapp.acw.bll;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.Serializable;

public final class Pos implements Serializable {
	private int _col = 0;
	private int _row = 0;

	public Pos () {
	}

	public Pos (int col, int row) {
		_col = col;
		_row = row;
	}

	public int getCol () {
		return _col;
	}

	public void setCol (int col) {
		this._col = col;
	}

	public int getRow () {
		return _row;
	}

	public void setRow (int row) {
		this._row = row;
	}

	@Override
	public boolean equals (@Nullable Object obj) {
		if (obj == null) {
			return false;
		}

		if (!(obj instanceof Pos)) {
			return false;
		}

		return ((Pos)obj)._col == _col && ((Pos)obj)._row == _row;
	}

	@NonNull
	@Override
	public String toString () {
		return "(" + _col + "," + _row + ")";
	}
}
