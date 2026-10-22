package dz.sayida.rozqi;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {

    private WebView webView;

    private static final String BASE_URL =
            "https://appassets.androidplatform.net/";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getWindow().setStatusBarColor(0xff3b2118);
        getWindow().setNavigationBarColor(0xff3b2118);

        webView = new WebView(this);
        setContentView(webView);

        WebSettings settings = webView.getSettings();

        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);

        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);

        settings.setMixedContentMode(
                WebSettings.MIXED_CONTENT_NEVER_ALLOW
        );

        settings.setJavaScriptCanOpenWindowsAutomatically(false);
        settings.setSupportMultipleWindows(false);

        configureNavigation();
        configureDialogs();
        loadInterface();
    }

    private void configureNavigation() {
        webView.setWebViewClient(new WebViewClient() {

            @Override
            public boolean shouldOverrideUrlLoading(
                    WebView view,
                    WebResourceRequest request
            ) {
                if (!request.isForMainFrame()) {
                    return true;
                }

                openExternalLink(request.getUrl());
                return true;
            }

            @Override
            public boolean shouldOverrideUrlLoading(
                    WebView view,
                    String url
            ) {
                openExternalLink(Uri.parse(url));
                return true;
            }
        });
    }

    private void openExternalLink(Uri uri) {
        if (uri == null) {
            return;
        }

        String scheme = uri.getScheme();

        if (!"https".equalsIgnoreCase(scheme)) {
            Toast.makeText(
                    this,
                    "يُسمح بروابط HTTPS فقط",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        String host = uri.getHost();

        if (host == null || host.isEmpty()) {
            return;
        }

        if ("appassets.androidplatform.net".equalsIgnoreCase(host)) {
            return;
        }

        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            intent.addCategory(Intent.CATEGORY_BROWSABLE);
            startActivity(intent);

        } catch (ActivityNotFoundException exception) {
            Toast.makeText(
                    this,
                    "لا يوجد تطبيق مناسب لفتح الرابط",
                    Toast.LENGTH_LONG
            ).show();
        }
    }

    private void configureDialogs() {
        webView.setWebChromeClient(new WebChromeClient() {

            @Override
            public boolean onJsAlert(
                    WebView view,
                    String url,
                    String message,
                    final JsResult result
            ) {
                new AlertDialog.Builder(MainActivity.this)
                        .setTitle("السيدة رزقي")
                        .setMessage(message)
                        .setPositiveButton(
                                "حسنًا",
                                (dialog, which) -> result.confirm()
                        )
                        .setOnCancelListener(
                                dialog -> result.cancel()
                        )
                        .show();

                return true;
            }

            @Override
            public boolean onJsConfirm(
                    WebView view,
                    String url,
                    String message,
                    final JsResult result
            ) {
                new AlertDialog.Builder(MainActivity.this)
                        .setTitle("تأكيد")
                        .setMessage(message)
                        .setPositiveButton(
                                "نعم",
                                (dialog, which) -> result.confirm()
                        )
                        .setNegativeButton(
                                "إلغاء",
                                (dialog, which) -> result.cancel()
                        )
                        .setOnCancelListener(
                                dialog -> result.cancel()
                        )
                        .show();

                return true;
            }
        });
    }

    private void loadInterface() {
        StringBuilder html = new StringBuilder();

        try (
                BufferedReader reader = new BufferedReader(
                        new InputStreamReader(
                                getAssets().open("index.html"),
                                StandardCharsets.UTF_8
                        )
                )
        ) {
            String line;

            while ((line = reader.readLine()) != null) {
                html.append(line).append('
');
            }

            webView.loadDataWithBaseURL(
                    BASE_URL,
                    html.toString(),
                    "text/html",
                    "UTF-8",
                    BASE_URL
            );

        } catch (Exception exception) {
            new AlertDialog.Builder(this)
                    .setTitle("تعذر فتح الواجهة")
                    .setMessage(
                            "تأكدي من وجود الملف:" +
                            "
app/src/main/assets/index.html"
                    )
                    .setPositiveButton(
                            "إغلاق",
                            (dialog, which) -> finish()
                    )
                    .setCancelable(false)
                    .show();
        }
    }

    @Override
    public void onBackPressed() {
        if (webView == null) {
            super.onBackPressed();
            return;
        }

        webView.evaluateJavascript(
                "(function() {" +
                "if (typeof window.appBack === 'function') {" +
                "window.appBack();" +
                "} else if (typeof window.go === 'function') {" +
                "window.go('home');" +
                "}" +
                "})();",
                null
        );
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
            webView = null;
        }

        super.onDestroy();
    }
}
