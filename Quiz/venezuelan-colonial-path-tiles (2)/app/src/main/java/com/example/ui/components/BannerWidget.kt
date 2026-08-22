package com.example.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Divider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.model.getRankForLevel
import com.example.model.getRegionForLevel

@Composable
fun TopParchmentBanner(
    nivelActual: Int,
    xp: Int,
    apelaciones: Int,
    modifier: Modifier = Modifier
) {
    val rank = getRankForLevel(nivelActual)
    val region = getRegionForLevel(nivelActual)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 6.dp)
            .shadow(elevation = 8.dp, shape = RoundedCornerShape(12.dp))
            .background(Color(0xFFFFFDF5), RoundedCornerShape(12.dp))
            .border(2.5.dp, Color(0xFFD4AF37), RoundedCornerShape(12.dp))
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar Institucional 'U'
                Box(
                    modifier = Modifier
                        .size(46.dp)
                        .background(Color(0xFF003893), CircleShape)
                        .border(2.5.dp, Color(0xFFD4AF37), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "U",
                        color = Color.White,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                // Rango y Región
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = rank,
                        color = Color(0xFF2C3E50),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = region.nombre,
                        color = Color(0xFF7F8C8D),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    LinearProgressIndicator(
                        progress = { (xp % 1000) / 1000f },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(5.dp),
                        color = Color(0xFFD4AF37),
                        trackColor = Color(0xFFE2E8F0)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))
            Divider(color = Color(0xFFD4AF37).copy(alpha = 0.5f), thickness = 1.dp)
            Spacer(modifier = Modifier.height(6.dp))

            // 5 Pergaminos de Apelaciones dibujados con Canvas
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Apelaciones: ",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF2C3E50)
                    )
                    for (i in 0 until 5) {
                        val activa = i < apelaciones
                        CanvasParchmentScroll(
                            isAvailable = activa,
                            modifier = Modifier.padding(horizontal = 2.dp)
                        )
                    }
                }

                Text(
                    text = "$xp XP",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Black,
                    color = Color(0xFF003893)
                )
            }
        }
    }
}

@Composable
fun CanvasParchmentScroll(
    isAvailable: Boolean,
    modifier: Modifier = Modifier
) {
    Canvas(
        modifier = modifier.size(width = 14.dp, height = 20.dp)
    ) {
        val goldColor = if (isAvailable) Color(0xFFD4AF37) else Color(0xFF7F8C8D)
        val paperColor = if (isAvailable) Color(0xFFFFF7D6) else Color(0xFFCBD5E1)

        // Cuerpo rectangular central del pergamino
        drawRoundRect(
            color = paperColor,
            topLeft = Offset(2f, 4f),
            size = Size(size.width - 4f, size.height - 8f),
            cornerRadius = CornerRadius(2f, 2f),
            style = Fill
        )
        drawRoundRect(
            color = goldColor,
            topLeft = Offset(2f, 4f),
            size = Size(size.width - 4f, size.height - 8f),
            cornerRadius = CornerRadius(2f, 2f),
            style = Stroke(width = 1.5f)
        )

        // Rollos superior e inferior del pergamino
        drawOval(
            color = goldColor,
            topLeft = Offset(0f, 0f),
            size = Size(size.width, 5f)
        )
        drawOval(
            color = goldColor,
            topLeft = Offset(0f, size.height - 5f),
            size = Size(size.width, 5f)
        )

        // Cinta/Sello rojo o gris en el centro
        drawRect(
            color = if (isAvailable) Color(0xFFCF142B) else Color(0xFF94A3B8),
            topLeft = Offset(size.width / 2f - 2f, 4f),
            size = Size(4f, size.height - 8f)
        )
    }
}
