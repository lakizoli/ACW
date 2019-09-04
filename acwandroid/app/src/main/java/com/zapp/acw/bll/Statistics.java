package com.zapp.acw.bll;

import java.io.Serializable;

public final class Statistics implements Serializable {
	public int failCount = 0;
	public int hintCount = 0;
	public double fillRatio = 0;
	public int fillDuration = 0;
	public boolean isFilled = false;
}
