package com.samoondigital.pdftyping

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class SharedNativeAdFactory(
    private val layoutInflater: LayoutInflater,
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.shared_native_ad, null) as NativeAdView

        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.mediaView = mediaView
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        (adView.headlineView as TextView).text = nativeAd.headline
        mediaView.mediaContent = nativeAd.mediaContent

        setOptionalText(adView.bodyView as TextView, nativeAd.body)

        val callToActionView = adView.callToActionView as Button
        if (nativeAd.callToAction == null) {
            callToActionView.visibility = View.GONE
        } else {
            callToActionView.text = nativeAd.callToAction
            callToActionView.visibility = View.VISIBLE
        }

        val iconView = adView.iconView as ImageView
        if (nativeAd.icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
        }

        bindNativeAdWhenMeasured(adView, nativeAd)
        return adView
    }


    private fun bindNativeAdWhenMeasured(adView: NativeAdView, nativeAd: NativeAd) {
        var isBound = false
        lateinit var layoutListener: View.OnLayoutChangeListener

        fun bindIfMeasured() {
            if (isBound || adView.width <= 0 || adView.height <= 0) return
            isBound = true
            adView.removeOnLayoutChangeListener(layoutListener)
            adView.setNativeAd(nativeAd)
        }

        layoutListener = View.OnLayoutChangeListener { _, _, _, right, bottom, _, _, _, _ ->
            if (right > 0 && bottom > 0) {
                bindIfMeasured()
            }
        }

        adView.addOnLayoutChangeListener(layoutListener)
        adView.post { bindIfMeasured() }
    }
    private fun setOptionalText(view: TextView, value: String?) {
        if (value.isNullOrBlank()) {
            view.visibility = View.GONE
        } else {
            view.text = value
            view.visibility = View.VISIBLE
        }
    }
}
