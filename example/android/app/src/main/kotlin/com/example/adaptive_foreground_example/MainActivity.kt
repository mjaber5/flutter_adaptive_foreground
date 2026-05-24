package com.example.adaptive_foreground_example

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register our native Android bottom navigation bar platform view factory
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "native_android_tab_bar",
            NativeTabBarFactory(flutterEngine.dartExecutor.binaryMessenger)
        )
    }
}

// MARK: - Native Tab Bar Platform View Factory
class NativeTabBarFactory(private val messenger: io.flutter.plugin.common.BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeTabBarView(context, viewId, args, messenger)
    }
}

// MARK: - Native Tab Bar Platform View Implementation
class NativeTabBarView(
    private val context: Context,
    private val viewId: Int,
    private val args: Any?,
    private val messenger: io.flutter.plugin.common.BinaryMessenger
) : PlatformView {

    private val linearLayout: LinearLayout = LinearLayout(context)
    private val channel: MethodChannel = MethodChannel(messenger, "native_tab_bar_$viewId")

    init {
        createNativeTabBar()
    }

    override fun getView(): View {
        return linearLayout
    }

    override fun dispose() {}

    private fun createNativeTabBar() {
        linearLayout.orientation = LinearLayout.HORIZONTAL
        linearLayout.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        linearLayout.gravity = Gravity.CENTER_VERTICAL

        // Parse creation params
        val params = args as? Map<String, Any>
        val currentIndex = params?.get("currentIndex") as? Int ?: 0
        val activeColorHex = params?.get("accentColor") as? String ?: "#007AFF"
        val isDark = params?.get("isDark") as? Boolean ?: false

        // Dynamic background tint mapping
        val bgColor = if (isDark) {
            Color.parseColor("#CC1A1A2E") // translucent dark
        } else {
            Color.parseColor("#CCF2F2F7") // translucent light
        }
        linearLayout.setBackgroundColor(bgColor)

        // Tab definitions using Android built-in drawables
        val tabs = listOf(
            Pair("Today", android.R.drawable.ic_menu_today),
            Pair("Games", android.R.drawable.ic_menu_compass),
            Pair("Apps", android.R.drawable.ic_menu_manage),
            Pair("Arcade", android.R.drawable.ic_media_play),
            Pair("Search", android.R.drawable.ic_menu_search)
        )

        for (i in tabs.indices) {
            val tab = tabs[i]

            // Layout for each tab item
            val itemContainer = LinearLayout(context)
            itemContainer.orientation = LinearLayout.VERTICAL
            itemContainer.gravity = Gravity.CENTER
            itemContainer.layoutParams = LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.MATCH_PARENT,
                1.0f
            )
            itemContainer.setOnClickListener {
                channel.invokeMethod("onTap", i)
            }

            // Tab Icon
            val iconView = ImageView(context)
            iconView.setImageResource(tab.second)
            val iconSize = (22 * context.resources.displayMetrics.density).toInt()
            val iconParams = LinearLayout.LayoutParams(iconSize, iconSize)
            iconParams.setMargins(0, 0, 0, 4)
            iconView.layoutParams = iconParams

            // Tab Label
            val labelView = TextView(context)
            labelView.text = tab.first
            labelView.textSize = 10f
            labelView.gravity = Gravity.CENTER_HORIZONTAL

            val isActive = i == currentIndex
            if (isActive) {
                val activeColor = Color.parseColor(activeColorHex)
                iconView.setColorFilter(activeColor)
                labelView.setTextColor(activeColor)
                labelView.typeface = android.graphics.Typeface.create(
                    android.graphics.Typeface.DEFAULT,
                    android.graphics.Typeface.BOLD
                )
            } else {
                val inactiveColor = if (isDark) Color.parseColor("#80FFFFFF") else Color.parseColor("#80000000")
                iconView.setColorFilter(inactiveColor)
                labelView.setTextColor(inactiveColor)
                labelView.typeface = android.graphics.Typeface.create(
                    android.graphics.Typeface.DEFAULT,
                    android.graphics.Typeface.NORMAL
                )
            }

            itemContainer.addView(iconView)
            itemContainer.addView(labelView)
            linearLayout.addView(itemContainer)
        }
    }
}
