package ric.com.advimagepicker;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Build;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.FileProvider;
import androidx.exifinterface.media.ExifInterface;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.squareup.picasso.Picasso;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import java.util.Collections;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * AdvImagePickerPlugin
 */
public class AdvImagePickerPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    private Activity activity;
    private Context context;
    private BinaryMessenger messenger;
    private ThreadPoolExecutor mDecodeThreadPool;

    public AdvImagePickerPlugin() {
        // A queue of Runnables
        BlockingQueue<Runnable> mDecodeWorkQueue = new LinkedBlockingQueue<>();
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
    }

    @SuppressWarnings("deprecation")
    public static void registerWith(
            final io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "adv_image_picker");

        AdvImagePickerPlugin plugin = new AdvImagePickerPlugin();
        plugin.activity = registrar.activity();
        plugin.context = registrar.context();
        plugin.messenger = registrar.messenger();

        channel.setMethodCallHandler(plugin);
    }

    @Override
    public void onMethodCall(MethodCall call, @Nullable final Result result) {
        switch (call.method) {
            case "getPermission":
                List<String> s =
                        (Build.VERSION.SDK_INT >= 33) ? Arrays.asList(Manifest.permission.CAMERA, Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO) : Arrays.asList(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE);

                Dexter.withContext(context)
                        .withPermissions(s)
                        .withListener(new MultiplePermissionsListener() {
                            @Override
                            public void onPermissionsChecked(MultiplePermissionsReport report) {
                                result.success(report.areAllPermissionsGranted());
                            }

                            @Override
                            public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {
                                token.continuePermissionRequest();
                            }
                        })
                        .check();
                break;
            case "getAlbums": {
                Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

                String[] projection = {
                        MediaStore.Images.Media.BUCKET_ID,
                        MediaStore.Images.Media.BUCKET_DISPLAY_NAME};

                final String orderBy = MediaStore.Images.Media.DISPLAY_NAME;

                Cursor cursor;

                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P) {
                    cursor = context.getContentResolver().query(uri, projection, null, null, orderBy + " DESC", null);
                } else {
                    cursor = context.getContentResolver().query(uri, projection, "1) GROUP BY (" + MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME, null, orderBy + " DESC");
                }

                ArrayList<HashMap<String, Object>> finalResult = new ArrayList<>();
                ArrayList<String> finalKeys = new ArrayList<>();

                if (cursor != null) {
                    int columnId = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID);
                    int columnName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);

                    while (cursor.moveToNext()) {
                        if (!finalKeys.contains(cursor.getString(columnId))) {
                            HashMap<String, Object> albumItem = new HashMap<>();

                            albumItem.put("name", cursor.getString(columnName));
                            albumItem.put("identifier", cursor.getString(columnId));
                            albumItem.put("assetCount", cursor.getCount());
                            finalKeys.add(cursor.getString(columnId));
                            finalResult.add(albumItem);
                        }
                    }

                    cursor.close();
                }

                result.success(finalResult);
                break;
            }
            case "getAlbumAssetsId": {
                String absolutePathOfImage;
                Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

                String[] projection = {MediaStore.Images.Media.DATA, MediaStore.Images.Media.BUCKET_DISPLAY_NAME};
                String albumName = call.argument("albumName");
                albumName = albumName.replaceAll("'", "''");

                final String orderBy = MediaStore.Images.Media.DATE_TAKEN + " DESC";
                Cursor cursor = context.getContentResolver().query(uri, projection, MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " = '" + albumName + "'", null, orderBy);
                int columnData = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);

                ArrayList<String> assetIds = new ArrayList<>();

                while (cursor.moveToNext()) {
                    absolutePathOfImage = cursor.getString(columnData);

                    assetIds.add(absolutePathOfImage);
                }

                cursor.close();
                result.success(assetIds);
                break;
            }
            case "getAlbumThumbnail": {
                final String imagePath = call.argument("imagePath");
                final int width = call.argument("width");
                final int height = call.argument("height");
                final int quality = call.argument("quality");
                GetThumbnailTask task = new GetThumbnailTask(this.context, this.messenger, imagePath, width, height, quality);

                task.executeOnExecutor(mDecodeThreadPool);
                result.success(true);
                break;
            }
            case "getAlbumOriginal": {
                final String imagePath = call.argument("imagePath");
                final int maxSize = call.argument("maxSize") == null ? 0 : (int) (call.argument("maxSize"));
                final int quality = call.argument("quality") == null ? 0 : (int) (call.argument("quality"));
                GetImageTask task = new GetImageTask(this.context, this.messenger, imagePath, quality, maxSize);

                task.executeOnExecutor(mDecodeThreadPool);
                result.success(true);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.context = binding.getApplicationContext();
        this.messenger = binding.getBinaryMessenger();

        // A queue of Runnables
        BlockingQueue<Runnable> mDecodeWorkQueue = new LinkedBlockingQueue<>();
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

        final MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "adv_image_picker");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {

    }

    static private class GetImageTask extends AsyncTask<String, Void, ByteBuffer> {
        @SuppressLint("StaticFieldLeak")
        Context context;
        BinaryMessenger messenger;
        String imagePath;
        int quality;
        int maxSize;
        Picasso picasso;

        GetImageTask(Context context, BinaryMessenger messenger, String imagePath, int quality, int maxSize) {
            super();
            this.context = context;
            this.messenger = messenger;
            this.imagePath = imagePath;
            this.quality = quality;
            this.maxSize = maxSize;
            this.picasso = new Picasso.Builder(this.context).listener(new Picasso.Listener() {
                @Override
                public void onImageLoadFailed(Picasso picasso, Uri uri, Exception exception) {
                    exception.printStackTrace();
                }
            }).build();
        }

        @Override
        protected ByteBuffer doInBackground(String... strings) {
            File file = new File(this.imagePath);
            String packageName = context.getPackageName();

            Uri contentUri = FileProvider.getUriForFile(context, packageName + ".fileprovider", file);
            byte[] bytesArray = null;

            try {
                Bitmap bitmap = picasso
                        .load(contentUri)
                        .config(Bitmap.Config.RGB_565)
                        .get();

                int rotate = 0;
                ExifInterface exif = new ExifInterface(this.imagePath);
                int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);

                if (maxSize != 0) {
                    double initialWidth = bitmap.getWidth();
                    double initialHeight = bitmap.getHeight();
                    int width = initialHeight < initialWidth ? maxSize : (int) (initialWidth / initialHeight * maxSize);
                    int height = initialWidth <= initialHeight ? maxSize : (int) (initialHeight / initialWidth * maxSize);
                    bitmap = Bitmap.createScaledBitmap(bitmap, width,
                            height, true);
                }

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
            return buffer;
        }

        @Override
        protected void onPostExecute(ByteBuffer buffer) {
            super.onPostExecute(buffer);
            this.messenger.send("adv_image_picker/image/fetch/original/" + imagePath, buffer);
        }
    }

    static private class GetThumbnailTask extends AsyncTask<String, Void, ByteBuffer> {
        @SuppressLint("StaticFieldLeak")
        Context context;
        BinaryMessenger messenger;
        String imagePath;
        int width;
        int height;
        int quality;
        Picasso picasso;

        GetThumbnailTask(Context context, BinaryMessenger messenger, String imagePath, int width, int height, int quality) {
            super();
            this.context = context;
            this.messenger = messenger;
            this.imagePath = imagePath;
            this.width = width;
            this.height = height;
            this.quality = quality;
            this.picasso = new Picasso.Builder(this.context).listener(new Picasso.Listener() {
                @Override
                public void onImageLoadFailed(Picasso picasso, Uri uri, Exception exception) {
                    exception.printStackTrace();
                }
            }).build();
        }

        @Override
        protected ByteBuffer doInBackground(String... strings) {
            File file = new File(this.imagePath);

            String packageName = context.getPackageName();
            Uri contentUri = FileProvider.getUriForFile(context, packageName + ".fileprovider", file);
            byte[] byteArray = null;

            try {
                Bitmap bitmap = picasso
                        .load(contentUri)
                        .config(Bitmap.Config.RGB_565)
                        .resize(this.width, this.height)
                        .centerCrop()
                        .get();

                int rotate = 0;

                ExifInterface exif = new ExifInterface(this.imagePath);
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
            }

            if (byteArray != null) {
                final ByteBuffer buffer = ByteBuffer.allocateDirect(byteArray.length);
                buffer.put(byteArray);
                return buffer;
            }

            return null;
        }

        @Override
        protected void onPostExecute(ByteBuffer byteBuffer) {
            super.onPostExecute(byteBuffer);
            this.messenger.send("adv_image_picker/image/fetch/thumbnails/" + imagePath, byteBuffer);
        }
    }
}