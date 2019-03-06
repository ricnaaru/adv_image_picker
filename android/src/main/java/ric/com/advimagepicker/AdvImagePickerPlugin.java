package ric.com.advimagepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.CursorIndexOutOfBoundsException;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.support.media.ExifInterface;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.FileProvider;
import android.util.Log;
import android.widget.Toast;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionDeniedResponse;
import com.karumi.dexter.listener.PermissionGrantedResponse;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.karumi.dexter.listener.single.PermissionListener;
import com.squareup.picasso.MemoryPolicy;
import com.squareup.picasso.Picasso;
import com.squareup.picasso.Transformation;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.media.ThumbnailUtils.OPTIONS_RECYCLE_INPUT;

/**
 * AdvImagePickerPlugin
 */
public class AdvImagePickerPlugin implements MethodCallHandler {
    private Activity activity;
    private Context context;
    private BinaryMessenger messenger;
    private Result pendingResult;
    private MethodCall methodCall;
    private ThreadPoolExecutor mDecodeThreadPool;
    private Picasso picasso;

    private AdvImagePickerPlugin(Registrar registrar) {
        this.activity = registrar.activity();
        this.context = registrar.context();
        this.messenger = registrar.messenger();

        // A queue of Runnables
        BlockingQueue<Runnable> mDecodeWorkQueue = new LinkedBlockingQueue<Runnable>();
        // Sets the amount of time an idle thread waits before terminating
        int KEEP_ALIVE_TIME = 1;
        // Sets the Time Unit to seconds
        TimeUnit KEEP_ALIVE_TIME_UNIT = TimeUnit.SECONDS;

        mDecodeThreadPool = new ThreadPoolExecutor(
                1,       // Initial pool size
                1,       // Max pool size
                KEEP_ALIVE_TIME,
                KEEP_ALIVE_TIME_UNIT,
                mDecodeWorkQueue);

        picasso = new Picasso.Builder(context).listener(new Picasso.Listener() {
            @Override public void onImageLoadFailed(Picasso picasso, Uri uri, Exception exception) {
                exception.printStackTrace();
            }
        }).build();
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "adv_image_picker");
        channel.setMethodCallHandler(new AdvImagePickerPlugin(registrar));
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        if (call.method.equals("getPermission")) {
            Dexter.withActivity(activity)
                    .withPermissions(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE)
                    .withListener(new MultiplePermissionsListener() {
                        @Override
                        public void onPermissionsChecked(MultiplePermissionsReport report) {
                            result.success(report.areAllPermissionsGranted());
                        }

                        @Override
                        public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {

                        }
                    }).check();
        } else if (call.method.equals("getAlbums")) {
            Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

            String[] projection = {"COUNT(*) as count",
                    MediaStore.Images.Media.BUCKET_ID,
                    MediaStore.Images.Media.BUCKET_DISPLAY_NAME};

            final String orderBy = MediaStore.Images.Media.DISPLAY_NAME;
            Cursor cursor = context.getContentResolver().query(uri, projection, "1) GROUP BY (" + MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME, null, orderBy + " DESC");

            ArrayList<HashMap<String, Object>> finalResult = new ArrayList<>();

            if (cursor != null) {
                int columnId = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID);
                int columnName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
                int columnCount = cursor.getColumnIndexOrThrow("count");


                while (cursor.moveToNext()) {
                    HashMap<String, Object> albumItem = new HashMap<>();

                    albumItem.put("name", cursor.getString(columnName));
                    albumItem.put("identifier", cursor.getString(columnId));
                    albumItem.put("assetCount", cursor.getInt(columnCount));

                    finalResult.add(albumItem);
                }

                cursor.close();
            }

            result.success(finalResult);
        } else if (call.method.equals("getAlbumAssetsId")) {
            String absolutePathOfImage = null;
            Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

            String[] projection = {MediaStore.Images.Media.DATA, MediaStore.Images.Media.BUCKET_DISPLAY_NAME};
            String albumName = call.argument("albumName");
            albumName = albumName.replaceAll("'", "''");

            final String orderBy = MediaStore.Images.Media.DATE_TAKEN + " DESC";
            Cursor cursor = context.getContentResolver().query(uri, projection, MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " = '" + albumName + "'", null, orderBy);
            int columnData = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);

            ArrayList<String> assetIds = new ArrayList<String>();

            while (cursor.moveToNext()) {
                absolutePathOfImage = cursor.getString(columnData);

                assetIds.add(absolutePathOfImage);
            }

            cursor.close();
            result.success(assetIds);
        } else if (call.method.equals("getAlbumThumbnail")) {
            final String albumId = call.argument("albumId");
            final String assetId = call.argument("assetId");
            final int width = call.argument("width");
            final int height = call.argument("height");
            final int quality = call.argument("quality");
            GetThumbnailTask task = new GetThumbnailTask(this.messenger, albumId, assetId, width, height, quality);

            task.executeOnExecutor(mDecodeThreadPool);
            result.success(true);
        } else if (call.method.equals("getAlbumOriginal")) {
            final String albumId = call.argument("albumId");
            final String assetId = call.argument("assetId");
            final int quality = call.argument("quality");
            GetImageTask task = new GetImageTask(this.messenger, albumId, assetId, quality);

            task.executeOnExecutor(mDecodeThreadPool);
            result.success(true);
        } else {
            result.notImplemented();
        }
    }

    private void clearMethodCallAndResult() {
        methodCall = null;
        pendingResult = null;
    }

    private class GetImageTask extends AsyncTask<String, Void, Void> {
        BinaryMessenger messenger;
        String albumId;
        String assetId;
        int quality;

        GetImageTask(BinaryMessenger messenger, String albumId, String assetId, int quality) {
            super();
            this.messenger = messenger;
            this.albumId = albumId;
            this.assetId = assetId;
            this.quality = quality;
        }

        @Override
        protected Void doInBackground(String... strings) {
            File file = new File(this.assetId);
            String packageName = context.getPackageName();

            Uri contentUri = FileProvider.getUriForFile(context,  packageName + ".fileprovider", file);
            byte[] bytesArray = null;

            try {
                Bitmap bitmap = picasso
                        .load(contentUri)
                        .config(Bitmap.Config.RGB_565)
                        .get();

                int rotate = 0;
                ExifInterface exif = new ExifInterface(this.assetId);
                int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);

                switch (orientation) {
                    case ExifInterface.ORIENTATION_ROTATE_270:
                        rotate = 270;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_180:
                        rotate = 180;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_90:
                        rotate = 90;
                        break;
                }

                if (rotate > 0) {
                    Matrix matrix = new Matrix();
                    matrix.postRotate(rotate);

                    bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(),
                            bitmap.getHeight(), matrix, true);
                }
                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, this.quality, bitmapStream);
                bytesArray = bitmapStream.toByteArray();
                bitmap.recycle();
            } catch (IOException e) {
                e.printStackTrace();
            }

            assert bytesArray != null;
            final ByteBuffer buffer = ByteBuffer.allocateDirect(bytesArray.length);
            buffer.put(bytesArray);
            this.messenger.send("adv_image_picker/image/fetch/original/" + albumId + "/" + assetId, buffer);
            return null;
        }
    }

    private class GetThumbnailTask extends AsyncTask<String, Void, Void> {
        BinaryMessenger messenger;
        String albumId;
        String assetId;
        int width;
        int height;
        int quality;

        GetThumbnailTask(BinaryMessenger messenger, String albumId, String assetId, int width, int height, int quality) {
            super();
            this.messenger = messenger;
            this.albumId = albumId;
            this.assetId = assetId;
            this.width = width;
            this.height = height;
            this.quality = quality;
        }

        @Override
        protected Void doInBackground(String... strings) {
            File file = new File(this.assetId);

            String packageName = context.getPackageName();
            Uri contentUri = FileProvider.getUriForFile(context, packageName + ".fileprovider", file);
            InputStream stream = null;
            byte[] byteArray = null;

            try {
                Bitmap bitmap = picasso
                        .load(contentUri)
                        .config(Bitmap.Config.RGB_565)
                        .resize(this.width, this.height)
                        .centerCrop()
                        .get();

                int rotate = 0;

                ExifInterface exif = new ExifInterface(this.assetId);
                int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);

                switch (orientation) {
                    case ExifInterface.ORIENTATION_ROTATE_270:
                        rotate = 270;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_180:
                        rotate = 180;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_90:
                        rotate = 90;
                        break;
                }

                if (rotate > 0) {
                    Matrix matrix = new Matrix();
                    matrix.postRotate(rotate);

                    bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(),
                            bitmap.getHeight(), matrix, true);
                }

                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, this.quality, bitmapStream);
                byteArray = bitmapStream.toByteArray();
                bitmap.recycle();
            } catch (IOException e) {
                e.printStackTrace();
                this.messenger.send("adv_image_picker/image/fetch/thumbnails/" + albumId + "/" + assetId, null);
            }

            if (byteArray != null) {
                final ByteBuffer buffer = ByteBuffer.allocateDirect(byteArray.length);
                buffer.put(byteArray);
                this.messenger.send("adv_image_picker/image/fetch/thumbnails/" + albumId + "/" + assetId, buffer);
            }

            return null;
        }
    }

    private static int getOrientation(Context context, Uri photoUri) {
        try {
            Cursor cursor = context.getContentResolver().query(photoUri,
                    new String[]{MediaStore.Images.ImageColumns.ORIENTATION}, null, null, null);

            if (cursor.getCount() != 1) {
                return -1;
            }

            cursor.moveToFirst();
            return cursor.getInt(0);
        } catch (CursorIndexOutOfBoundsException e) {

        }
        return -1;
    }


}