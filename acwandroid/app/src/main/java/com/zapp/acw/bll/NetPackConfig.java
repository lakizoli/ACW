package com.zapp.acw.bll;

import java.util.ArrayList;

public final class NetPackConfig {
	public static class NetPackConfigItem {
		public String label;
		public String fileID;
		public int size = 0;
	}

	private ArrayList<NetPackConfigItem> _items = new ArrayList<> ();

	private NetPackConfig () {
	}

	public static native NetPackConfig parse (String path);

	public int countOfLanguages () {
		return _items.size ();
	}

	public interface ConfigEnumerator {
		void apply (NetPackConfigItem item);
	}

	public void enumerateLanguagesWihtBlock (ConfigEnumerator block) {
		if (_items != null && block != null) {
			for (NetPackConfigItem item : _items) {
				block.apply (item);
			}
		}
	}
}
