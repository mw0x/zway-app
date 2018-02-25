
// ============================================================ //
//
//   d88888D db   d8b   db  .d8b.  db    db
//   YP  d8' 88   I8I   88 d8' `8b `8b  d8'
//      d8'  88   I8I   88 88ooo88  `8bd8'
//     d8'   Y8   I8I   88 88~~~88    88
//    d8' db `8b d8'8b d8' 88   88    88
//   d88888P  `8b8' `8d8'  YP   YP    YP
//
//   open-source, cross-platform, crypto-messenger
//
//   Copyright (C) 2018 Marc Weiler
//
//   This program is free software: you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation, either version 3 of the License, or
//   (at your option) any later version.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
//   You should have received a copy of the GNU General Public License
//   along with this program. If not, see <http://www.gnu.org/licenses/>.
//
// ============================================================ //

package de.atomicode.zway;

import org.qtproject.qt5.android.bindings.QtActivity;

import android.os.Build;
import android.os.Bundle;
import android.os.PersistableBundle;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;

import android.view.WindowManager;
import android.view.View;
import android.view.ViewTreeObserver;
import android.widget.FrameLayout;
import android.graphics.Rect;

import android.telephony.TelephonyManager;

import android.database.Cursor;
import android.provider.ContactsContract;

import android.app.NotificationManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.support.v4.app.NotificationCompat;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import com.google.firebase.iid.FirebaseInstanceId;

import android.widget.Toast;

import android.util.Log;

// ============================================================ //

public class ZwayActivity extends QtActivity {

    private static ZwayActivity mInstance;


    private NotificationManager mNotifManager = null;

    private int mStatusBarHeight;

    private int mUsableHeightPrevious;


    private String mFcmToken = null;


    @Override
    public void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);


        mInstance = this;


        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {

            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        }


        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {

            // get status bar height

            int statusBarHeightId = getResources().getIdentifier("status_bar_height", "dimen", "android");

            if (statusBarHeightId > 0) {

                mStatusBarHeight = getResources().getDimensionPixelSize(statusBarHeightId);
            }

            // watch for layout changes

            FrameLayout content = (FrameLayout) findViewById(android.R.id.content);

            final View childOfContent = content.getChildAt(0);

            childOfContent.getViewTreeObserver().addOnGlobalLayoutListener(

                new ViewTreeObserver.OnGlobalLayoutListener() {

                    public void onGlobalLayout() {

                        Rect r = new Rect();

                        childOfContent.getWindowVisibleDisplayFrame(r);

                        int usableHeight = r.bottom - mStatusBarHeight;

                        if (usableHeight != mUsableHeightPrevious) {

                            int usableHeightSansKeyboard = childOfContent.getRootView().getHeight() - mStatusBarHeight;

                            int heightDelta = usableHeightSansKeyboard - usableHeight;

                            if (heightDelta > (usableHeightSansKeyboard / 4)) {

                                // keyboard probably just became visible

                                try {

                                    JSONObject data = new JSONObject();

                                    data.put("height", usableHeight);

                                    data.put("delta", heightDelta);

                                    nativeCallback(3000, data.toString());
                                }
                                catch (JSONException e) {

                                }
                            }
                            else {

                                // keyboard probably just became hidden

                                try {

                                    JSONObject data = new JSONObject();

                                    data.put("height", usableHeightSansKeyboard);

                                    data.put("delta", heightDelta);

                                    nativeCallback(3001, data.toString());
                                }
                                catch (JSONException e) {

                                }
                            }

                            mUsableHeightPrevious = usableHeight;
                        }
                    }
                }
            );
        }

        mNotifManager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);


        mFcmToken = FirebaseInstanceId.getInstance().getToken();


    }


    /*
    public void onNewIntent(Intent intent) {

        Bundle extras = intent.getExtras();

        if (extras != null) {

            if (extras.getInt("src") > 0) {

                nativeCallback(101, extras);
            }
        }
    }
    */


    public static void nativeInit() {

        if (needsPermissionCheck()) {

            String permissions =
                "android.permission.WRITE_EXTERNAL_STORAGE|" +
                "android.permission.WAKE_LOCK";

            requestPermission(1, permissions);

        }
        else {

            nativeInitCallback(true);
        }
    }


    public static void nativeInitCallback(boolean permissionsGranted) {

        try {

            JSONObject data = new JSONObject();

            data.put("fcmToken", mInstance.mFcmToken);

            data.put("permissionsGranted", permissionsGranted);

            nativeCallback(1000, data.toString());
        }
        catch (JSONException e) {

        }
    }


    public static boolean needsPermissionCheck() {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {

            return false;
        }

        return true;
    }


    public static void requestPermission(int requestCode, String permissions) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

            String[] perm = permissions.split("\\|");

            for (String p : perm) {

                Log.d("ZWAY ACTIVITY", "REQUEST PERMISSION: " + p);

            }

            mInstance.requestPermissions(perm, requestCode);
        }
    }


    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == 1) {

            boolean permissionsGranted = true;

            for (int r : grantResults) {

                if (r != PackageManager.PERMISSION_GRANTED) {

                    permissionsGranted = false;

                    break;
                }
            }

            nativeInitCallback(permissionsGranted);
        }
    }


    public static void showNotification(int type, String data) {

        if (mInstance != null) {

            try {

                JSONObject d = new JSONObject(data);

                Intent intent = new Intent(mInstance, ZwayActivity.class);

                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

                PendingIntent pendingIntent = PendingIntent.getActivity(mInstance, type, intent, PendingIntent.FLAG_ONE_SHOT);

                NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(mInstance)
                        .setSmallIcon(android.R.drawable.stat_notify_chat)
                        .setContentTitle(d.getString("title"))
                        .setContentText(d.getString("text"))
                        .setAutoCancel(true)
                        .setDefaults(Notification.DEFAULT_ALL)
                        .setContentIntent(pendingIntent);

                mInstance.mNotifManager.notify(type, notificationBuilder.build());

            }
            catch (JSONException e) {

            }
        }
    }


    public static void sendToBack() {

        mInstance.moveTaskToBack(true);
    }


    public static String getPhoneNumber() {

        TelephonyManager mgr = (TelephonyManager)mInstance.getSystemService(Context.TELEPHONY_SERVICE);

        String phoneNumber = mgr.getLine1Number();

        return phoneNumber;
    }


    public static String getContactsJson() {

        Cursor phones = mInstance.getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null,null,null, null);

        JSONObject obj = new JSONObject();

        while (phones.moveToNext()) {

            String name = phones.getString(phones.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME));

            String phoneNumber = phones.getString(phones.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));

            if (!obj.has(name)) {

                try {

                    JSONArray arr = new JSONArray();

                    arr.put(phoneNumber);

                    obj.put(name, arr);
                }
                catch (JSONException e) {

                }
            }
            else {

                try {

                    JSONArray arr = obj.getJSONArray(name);

                    arr.put(phoneNumber);
                }
                catch (JSONException e) {

                }
            }
        }

        phones.close();

        return obj.toString();
    }


    public static int getStatusBarHeight() {

        return mInstance.mStatusBarHeight;
    }


    static native void nativeCallback(int id, String data);


}

// ============================================================ //
