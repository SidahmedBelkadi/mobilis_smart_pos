package com.ai_univers.smart_point_of_sale.vision;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.View;

import com.ai_univers.smart_point_of_sale.R;

public class OverlayView extends View {

    private Paint paint;
    private Paint textPaint;
    private Rect rect;
    private String text;

    public OverlayView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        paint = new Paint();
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeWidth(4 * getResources().getDisplayMetrics().density); // Scaled stroke width
        paint.setAntiAlias(true);

        textPaint = new Paint();
        textPaint.setStyle(Paint.Style.FILL);
        textPaint.setTextSize(16 * getResources().getDisplayMetrics().scaledDensity); // Scaled text size
        textPaint.setAntiAlias(true);

        TypedArray a = context.getTheme().obtainStyledAttributes(attrs, R.styleable.OverlayView, 0, 0);
        try {
            paint.setColor(a.getColor(R.styleable.OverlayView_rectangleColor, Color.GREEN));
            textPaint.setColor(a.getColor(R.styleable.OverlayView_textColor, Color.WHITE));
        } finally {
            a.recycle();
        }
    }

    public void setRect(Rect rect, String text) {
        this.rect = rect;
        this.text = text;
        invalidate(); // Trigger re-draw
    }

    public Rect calculateRectangle(int viewWidth, int viewHeight) {
        int rectWidth = (int) (viewWidth * 0.85);  // 80% of width
        int rectHeight = (int) (viewHeight * 0.35); // 40% of height

        int left = (viewWidth - rectWidth) / 2;
        int top = (viewHeight - rectHeight) / 2;
        int right = left + rectWidth;
        int bottom = top + rectHeight;

        return new Rect(left, top, right, bottom);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        if (rect != null) {
            // Draw a semi-transparent background
            Paint overlayPaint = new Paint();
            overlayPaint.setStyle(Paint.Style.FILL);
            overlayPaint.setColor(Color.BLACK); // Background color
            overlayPaint.setAlpha(150); // Adjust alpha for opacity (0 = fully transparent, 255 = fully opaque)

            // Draw areas outside the rectangle
            canvas.drawRect(0, 0, getWidth(), rect.top, overlayPaint); // Top area
            canvas.drawRect(0, rect.top, rect.left, rect.bottom, overlayPaint); // Left area
            canvas.drawRect(rect.right, rect.top, getWidth(), rect.bottom, overlayPaint); // Right area
            canvas.drawRect(0, rect.bottom, getWidth(), getHeight(), overlayPaint); // Bottom area

            // Draw the rounded rectangle
            float cornerRadius = 0 * getResources().getDisplayMetrics().density; // Corner radius in pixels
            canvas.drawRoundRect(
                    rect.left,
                    rect.top,
                    rect.right,
                    rect.bottom,
                    cornerRadius,
                    cornerRadius,
                    paint
            );

            // Draw text above the rectangle
            if (text != null) {
                float textYPosition = rect.top - 20; // Offset above the rectangle
                if (textYPosition < 0) {
                    textYPosition = rect.bottom + 50; // Place below if above is out of bounds
                }
                canvas.drawText(text, rect.left, textYPosition, textPaint);
            }
        }
    }

}
