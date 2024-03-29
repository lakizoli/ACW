package com.zapp.acw.bll;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.Serializable;

@Keep
public final class Pos implements Serializable {
	private static final long serialVersionUID = 0x0002;

	private int _row = 0;
	private int _col = 0;

	public Pos () {
	}

	public Pos (int row, int col) {
		_row = row;
		_col = col;
	}

	public int getRow () {
		return _row;
	}

	public void setRow (int row) {
		this._row = row;
	}

	public int getCol () {
		return _col;
	}

	public void setCol (int col) {
		this._col = col;
	}

	@Override
	public boolean equals (@Nullable Object obj) {
		if (obj == null) {
			return false;
		}

		if (!(obj instanceof Pos)) {
			return false;
		}

		return ((Pos) obj)._row == _row && ((Pos) obj)._col == _col;
	}

	@Override
	public int hashCode () {
		return (_row & 0xFFFF) << 16 | (_col & 0xFFFF);
	}

	@NonNull
	@Override
	public String toString () {
		return "(" + _row + "," + _col + ")";
	}
}
