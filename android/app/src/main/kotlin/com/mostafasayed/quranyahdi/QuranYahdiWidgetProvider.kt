package com.mostafasayed.quranyahdi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// The home-screen prayer widget: the next prayer, its time and the city.
class QuranYahdiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.quran_yahdi_widget).apply {
                    setOnClickPendingIntent(
                        R.id.widget_root,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                    )
                    setTextViewText(
                        R.id.widget_app_name,
                        widgetData.getString("app_name", "") ?: "",
                    )
                    setTextViewText(
                        R.id.widget_label,
                        widgetData.getString("next_prayer_label", "") ?: "",
                    )
                    setTextViewText(
                        R.id.widget_prayer,
                        widgetData.getString("next_prayer", "") ?: "",
                    )
                    setTextViewText(
                        R.id.widget_time,
                        widgetData.getString("next_prayer_time", "") ?: "",
                    )
                    setTextViewText(
                        R.id.widget_city,
                        widgetData.getString("city", "") ?: "",
                    )
                }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
