import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { line, bar, pie }

class ChartWidget extends StatelessWidget {
  final Map<dynamic, double> data;
  final ChartType type;

  const ChartWidget({
    Key? key,
    required this.data,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
    }
  }

  Widget _buildLineChart() {
    final sortedKeys = data.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      sortedKeys[value.toInt()].toString(),
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedKeys.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), data[sortedKeys[entry.key]]!);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final sortedKeys = data.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      sortedKeys[value.toInt()].toString(),
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedKeys.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: data[sortedKeys[entry.key]]!,
                color: Colors.green,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.yellow,
      Colors.teal,
      Colors.indigo,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: data.entries.map((entry) {
          final index = data.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${entry.key}',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _Badge(
              entry.value.toStringAsFixed(0),
              size: 38,
              borderColor: colors[index % colors.length],
            ),
            badgePositionPercentageOffset: .98,
          );
        }).toList(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: FittedBox(
          child: Text(
            text,
            style: TextStyle(
              color: borderColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
