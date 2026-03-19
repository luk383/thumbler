package com.wolflab.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WolfLabWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.wolflab_widget)

            val widgetData = HomeWidgetPlugin.getData(context)
            val streak = widgetData.getInt("streak", 0)
            val due = widgetData.getInt("due_cards", 0)
            val xp = widgetData.getInt("daily_xp", 0)

            views.setTextViewText(R.id.widget_streak, "🔥 $streak")
            views.setTextViewText(R.id.widget_due, "$due")
            views.setTextViewText(R.id.widget_xp, "$xp XP")

            // Tap opens the app
            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_streak, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
