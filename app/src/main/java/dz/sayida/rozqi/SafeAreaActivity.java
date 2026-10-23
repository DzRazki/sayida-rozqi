package dz.sayida.rozqi;

import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;

public class SafeAreaActivity extends MainActivity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        ViewGroup content = findViewById(android.R.id.content);
        if (content == null || content.getChildCount() == 0) return;
        final View container = content.getChildAt(0);
        final View decor = getWindow().getDecorView();
        container.setOnApplyWindowInsetsListener((view, insets) -> {
            boolean fullScreen = (decor.getSystemUiVisibility() & View.SYSTEM_UI_FLAG_FULLSCREEN) != 0;
            if (fullScreen) {
                view.setPadding(0, 0, 0, 0);
                return insets;
            }
            if (Build.VERSION.SDK_INT >= 30) {
                Insets bars = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom);
                return WindowInsets.CONSUMED;
            }
            view.setPadding(insets.getSystemWindowInsetLeft(), insets.getSystemWindowInsetTop(), insets.getSystemWindowInsetRight(), insets.getSystemWindowInsetBottom());
            return insets.consumeSystemWindowInsets();
        });
        decor.setOnSystemUiVisibilityChangeListener(flags -> container.requestApplyInsets());
        container.post(() -> container.requestApplyInsets());
    }
}
