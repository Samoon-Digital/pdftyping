package com.samoondigital.pdftyping

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

class SharedNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = NativeAdView(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.WHITE)
        }

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        adView.addView(container)

        val mediaView = MediaView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(132)
            )
            setBackgroundColor(Color.rgb(245, 247, 250))
        }
        container.addView(mediaView)
        adView.mediaView = mediaView
        mediaView.mediaContent = nativeAd.mediaContent

        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(10), 0, 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        container.addView(row)

        val iconView = ImageView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(46), dp(46)).apply {
                marginEnd = dp(10)
            }
            scaleType = ImageView.ScaleType.CENTER_CROP
        }
        row.addView(iconView)
        adView.iconView = iconView

        val textColumn = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        row.addView(textColumn)

        val headlineView = TextView(context).apply {
            setTextColor(Color.rgb(16, 32, 51))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 2
        }
        textColumn.addView(headlineView)
        adView.headlineView = headlineView

        val bodyView = TextView(context).apply {
            setTextColor(Color.rgb(91, 100, 114))
            textSize = 12f
            maxLines = 2
        }
        textColumn.addView(bodyView)
        adView.bodyView = bodyView

        val metaRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(4), 0, 0)
        }
        textColumn.addView(metaRow)

        val adBadge = TextView(context).apply {
            text = "Ad"
            setTextColor(Color.WHITE)
            textSize = 10f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(5), dp(1), dp(5), dp(1))
            setBackgroundColor(Color.rgb(11, 58, 110))
        }
        metaRow.addView(adBadge)

        val advertiserView = TextView(context).apply {
            setTextColor(Color.rgb(91, 100, 114))
            textSize = 11f
            maxLines = 1
            setPadding(dp(6), 0, 0, 0)
        }
        metaRow.addView(advertiserView)
        adView.advertiserView = advertiserView

        val ctaView = Button(context).apply {
            minHeight = 0
            minWidth = 0
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.rgb(11, 58, 110))
            setPadding(dp(10), dp(4), dp(10), dp(4))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dp(40)
            ).apply { marginStart = dp(8) }
        }
        row.addView(ctaView)
        adView.callToActionView = ctaView

        headlineView.text = nativeAd.headline
        bodyView.bindText(nativeAd.body)
        advertiserView.bindText(nativeAd.advertiser)
        ctaView.bindText(nativeAd.callToAction)

        nativeAd.icon?.drawable?.let {
            iconView.setImageDrawable(it)
            iconView.visibility = View.VISIBLE
        } ?: run { iconView.visibility = View.GONE }

        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun TextView.bindText(value: String?) {
        text = value.orEmpty()
        visibility = if (value.isNullOrBlank()) View.GONE else View.VISIBLE
    }

    private fun dp(value: Int): Int = (value * context.resources.displayMetrics.density).toInt()
}
