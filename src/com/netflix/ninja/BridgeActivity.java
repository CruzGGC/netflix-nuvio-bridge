package com.netflix.ninja;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.widget.Toast;

/** Opens Nuvio and closes itself immediately (Theme.NoDisplay requires finish() before onResume). */
public class BridgeActivity extends Activity {
    private static final String TARGET = "com.nuvio.app";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        PackageManager pm = getPackageManager();
        Intent launch = pm.getLeanbackLaunchIntentForPackage(TARGET);
        if (launch == null) launch = pm.getLaunchIntentForPackage(TARGET);
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
            startActivity(launch);
        } else {
            Toast.makeText(this, "Nuvio is not installed", Toast.LENGTH_LONG).show();
        }
        finish();
    }
}
