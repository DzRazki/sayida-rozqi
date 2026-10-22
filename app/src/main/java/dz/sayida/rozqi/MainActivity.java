package dz.sayida.rozqi;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.content.Intent;
import android.net.Uri;
public class MainActivity extends Activity {
 private WebView web;
 @Override public void onCreate(Bundle state) {
  super.onCreate(state);
  getWindow().setStatusBarColor(0xff3b2118);
  getWindow().setNavigationBarColor(0xff3b2118);
  web=new WebView(this); setContentView(web);
  web.getSettings().setJavaScriptEnabled(true);
  web.getSettings().setDomStorageEnabled(true);
  web.getSettings().setAllowFileAccess(false);
  web.getSettings().setAllowContentAccess(false);
  web.setWebViewClient(new WebViewClient(){
   @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r){
    Uri u=r.getUrl();
    if("https".equals(u.getScheme())) { try { startActivity(new Intent(Intent.ACTION_VIEW,u)); } catch(Exception ignored) {} }
    return true;
   }
  });
  web.loadUrl("file:///android_asset/index.html");
 }
 @Override public void onBackPressed(){ web.evaluateJavascript("window.appBack && window.appBack()",null); }
 @Override protected void onDestroy(){ if(web!=null) web.destroy(); super.onDestroy(); }
}
