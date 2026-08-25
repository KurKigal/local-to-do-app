package com.emirhankeser.flowtask

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FlowTaskWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(
                context.packageName,
                R.layout.flowtask_widget,
            )

            views.setTextViewText(
                R.id.widget_date,
                widgetData.getString(
                    "widget_date",
                    "",
                ) ?: "",
            )

            val count = widgetData.getInt(
                "widget_count",
                0,
            )

            views.setTextViewText(
                R.id.widget_footer,
                if (count == 1) {
                    "1 remaining"
                } else {
                    "$count remaining"
                },
            )

            val openTodayIntent =
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse(
                        "flowtaskwidget://today/",
                    ),
                )

            views.setOnClickPendingIntent(
                R.id.widget_root,
                openTodayIntent,
            )

            val newTaskIntent =
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse(
                        "flowtaskwidget://new/",
                    ),
                )

            views.setOnClickPendingIntent(
                R.id.widget_add,
                newTaskIntent,
            )

            bindTask(
                context = context,
                views = views,
                widgetData = widgetData,
                index = 0,
                rowId = R.id.widget_task_0,
                doneId = R.id.widget_task_0_done,
                titleId = R.id.widget_task_0_title,
                dueId = R.id.widget_task_0_due,
            )

            bindTask(
                context = context,
                views = views,
                widgetData = widgetData,
                index = 1,
                rowId = R.id.widget_task_1,
                doneId = R.id.widget_task_1_done,
                titleId = R.id.widget_task_1_title,
                dueId = R.id.widget_task_1_due,
            )

            bindTask(
                context = context,
                views = views,
                widgetData = widgetData,
                index = 2,
                rowId = R.id.widget_task_2,
                doneId = R.id.widget_task_2_done,
                titleId = R.id.widget_task_2_title,
                dueId = R.id.widget_task_2_due,
            )

            views.setViewVisibility(
                R.id.widget_empty,
                if (count == 0) {
                    View.VISIBLE
                } else {
                    View.GONE
                },
            )

            views.setViewVisibility(
                R.id.widget_footer,
                if (count == 0) {
                    View.GONE
                } else {
                    View.VISIBLE
                },
            )

            appWidgetManager.updateAppWidget(
                widgetId,
                views,
            )
        }
    }

    private fun bindTask(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        index: Int,
        rowId: Int,
        doneId: Int,
        titleId: Int,
        dueId: Int,
    ) {
        val taskId =
            widgetData.getString(
                "widget_task_${index}_id",
                "",
            ) ?: ""

        if (taskId.isEmpty()) {
            views.setViewVisibility(
                rowId,
                View.GONE,
            )
            return
        }

        views.setViewVisibility(
            rowId,
            View.VISIBLE,
        )

        val title =
            widgetData.getString(
                "widget_task_${index}_title",
                "",
            ) ?: ""

        val due =
            widgetData.getString(
                "widget_task_${index}_due",
                "",
            ) ?: ""

        views.setTextViewText(
            titleId,
            title,
        )

        views.setTextViewText(
            dueId,
            due,
        )

        views.setViewVisibility(
            dueId,
            if (due.isEmpty()) {
                View.GONE
            } else {
                View.VISIBLE
            },
        )

        val encodedTaskId =
            Uri.encode(taskId)

        val openTaskIntent =
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(
                    "flowtaskwidget://task/$encodedTaskId",
                ),
            )

        views.setOnClickPendingIntent(
            rowId,
            openTaskIntent,
        )

        val doneIntent =
            HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse(
                    "flowtaskwidget://done/$encodedTaskId?taskId=$encodedTaskId",
                ),
            )

        views.setOnClickPendingIntent(
            doneId,
            doneIntent,
        )
    }
}
