# -*- coding: utf-8 -*-
"""
飞书告警网关
- 接收 Alertmanager 的 Webhook 告警
- 转换为飞书卡片格式
- 发送到飞书群
"""

import requests
import json
import logging
from flask import Flask, request, jsonify
from datetime import datetime
from dateutil import parser  # 需要安装: pip install python-dateutil

# ================== 配置 ==================
# 飞书机器人 Webhook 地址
FEISHU_WEBHOOK_URL = "https://open.feishu.cn/open-apis/bot/v2/hook/9d7b1972-abf7-40ee-b115-e553cacce602"

# Flask 应用配置
app = Flask(__name__)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def format_time(time_str):
    """格式化时间字符串"""
    if not time_str or time_str == "0001-01-01T00:00:00Z":
        return ""
    try:
        # 尝试解析 ISO 8601 格式
        dt = parser.parse(time_str)
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except:
        return time_str


def build_alert_card(alerts_data):
    """
    根据 Alertmanager 告警数据构建飞书卡片
    """
    # 解析告警信息（如果是多条告警，取第一条）
    alerts = alerts_data.get("alerts", [])
    if not alerts:
        return None
    
    alert = alerts[0]
    labels = alert.get("labels", {})
    annotations = alert.get("annotations", {})
    
    # 提取告警变量
    alarm_cluster = labels.get("origin_prometheus", "未知集群")
    alarm_namespace = labels.get("namespace", "未知命名空间")
    alarm_type = labels.get("severity", "warning")
    alarm_pod = labels.get("pod", "未知Pod")
    alarm_name = labels.get("alertname", "未知告警")
    alarm_instance = labels.get("instance", "未知地址")
    
    # 提取告警详情
    alarm_description = annotations.get("description", annotations.get("summary", "无详细信息"))
    
    # 获取告警状态
    status = alert.get("status", "firing")
    
    # 获取开始时间和结束时间
    starts_at = alert.get("startsAt", "")
    ends_at = alert.get("endsAt", "")
    
    # 格式化时间
    alarm_start_time = format_time(starts_at)
    alarm_end_time = format_time(ends_at)
    
    # 判断是否是恢复告警（status 为 resolved 或者 endsAt 不为空且不是零值）
    is_resolved = (status == "resolved") or (ends_at and ends_at != "0001-01-01T00:00:00Z")
    
    # 根据状态设置卡片颜色和标题
    if is_resolved:
        # 恢复告警
        status_color = "green"
        status_text = "已恢复"
        card_template = "green"
        header_title = f"✅ {alarm_name} - 已恢复"
        # 恢复时计算持续时间
        duration_text = ""
        if alarm_start_time and alarm_end_time:
            try:
                start_dt = parser.parse(starts_at)
                end_dt = parser.parse(ends_at)
                duration = end_dt - start_dt
                minutes = int(duration.total_seconds() / 60)
                seconds = int(duration.total_seconds() % 60)
                if minutes > 0:
                    duration_text = f" (持续 {minutes} 分钟 {seconds} 秒)"
                else:
                    duration_text = f" (持续 {seconds} 秒)"
            except:
                pass
    else:
        # 触发告警
        status_color = "red"
        status_text = "紧急"
        card_template = "red"
        header_title = f"🚨 {alarm_name} - 告警触发"
        duration_text = ""
    
    # 构建恢复时间显示内容
    if alarm_end_time:
        recovery_display = f"{alarm_end_time}{duration_text}"
    else:
        recovery_display = "未恢复"
    
    # 构建卡片
    card = {
        "schema": "2.0",
        "config": {
            "update_multi": True,
            "style": {
                "text_size": {
                    "normal_v2": {
                        "default": "normal",
                        "pc": "normal",
                        "mobile": "heading"
                    }
                }
            }
        },
        "header": {
            "title": {
                "tag": "plain_text",
                "content": header_title
            },
            "subtitle": {
                "tag": "plain_text",
                "content": f"状态: {status_text}"
            },
            "text_tag_list": [
                {
                    "tag": "text_tag",
                    "text": {
                        "tag": "plain_text",
                        "content": status_text
                    },
                    "color": status_color
                }
            ],
            "template": card_template,
            "icon": {
                "tag": "standard_icon",
                "token": "alert-circle_outlined"
            },
            "padding": "12px 8px 12px 8px"
        },
        "body": {
            "direction": "vertical",
            "horizontal_spacing": "8px",
            "vertical_spacing": "8px",
            "horizontal_align": "left",
            "vertical_align": "top",
            "elements": [
                {
                    "tag": "column_set",
                    "flex_mode": "stretch",
                    "horizontal_spacing": "12px",
                    "horizontal_align": "left",
                    "columns": [
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "purple-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='purple'>📦 告警集群</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_cluster}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        },
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "red-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='red'>⚠️ 告警级别</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_type}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        },
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "purple-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='purple'>🔹 namespace</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_namespace}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        }
                    ],
                    "margin": "0px 0px 0px 0px"
                },
                {
                    "tag": "column_set",
                    "flex_mode": "stretch",
                    "horizontal_spacing": "12px",
                    "horizontal_align": "left",
                    "columns": [
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "violet-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='violet'>📌 告警名称</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_name}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        },
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "violet-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='violet'>🔩 pod-name</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_pod}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        },
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "blue-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='blue'>🖥️ instance</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_instance}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        }
                    ],
                    "margin": "0px 0px 0px 0px"
                },
                {
                    "tag": "column_set",
                    "flex_mode": "stretch",
                    "horizontal_spacing": "12px",
                    "horizontal_align": "left",
                    "columns": [
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "blue-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='blue'>🕒 告警时间</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{alarm_start_time}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        },
                        {
                            "tag": "column",
                            "width": "weighted",
                            "background_style": "blue-50",
                            "elements": [
                                {
                                    "tag": "markdown",
                                    "content": "<font color='blue'>✅ 恢复时间</font>",
                                    "text_size": "normal"
                                },
                                {
                                    "tag": "markdown",
                                    "content": f"{recovery_display}",
                                    "text_align": "left",
                                    "text_size": "normal_v2"
                                }
                            ],
                            "padding": "12px 12px 12px 12px",
                            "vertical_spacing": "4px",
                            "horizontal_align": "left",
                            "vertical_align": "top",
                            "weight": 1
                        }
                    ],
                    "margin": "0px 0px 0px 0px"
                },
                {
                    "tag": "markdown",
                    "content": f"**<font color='red'>详情信息</font>**\n{alarm_description}",
                    "text_align": "left",
                    "text_size": "normal_v2",
                    "margin": "0px 0px 0px 0px"
                },
                {
                    "tag": "column_set",
                    "flex_mode": "stretch",
                    "horizontal_spacing": "8px",
                    "horizontal_align": "left",
                    "columns": [
                        {
                            "tag": "column",
                            "width": "auto",
                            "elements": [
                                {
                                    "tag": "button",
                                    "text": {
                                        "tag": "plain_text",
                                        "content": "已忽略"
                                    },
                                    "type": "primary_filled",
                                    "width": "default",
                                    "behaviors": [
                                        {
                                            "type": "callback",
                                            "value": {
                                                "action": "ignore"
                                            }
                                        }
                                    ],
                                    "margin": "4px 0px 4px 0px",
                                    "element_id": "Xy96asGAnhebwhd_zesc"
                                }
                            ],
                            "vertical_spacing": "8px",
                            "horizontal_align": "left",
                            "vertical_align": "top"
                        },
                        {
                            "tag": "column",
                            "width": "auto",
                            "elements": [
                                {
                                    "tag": "button",
                                    "text": {
                                        "tag": "plain_text",
                                        "content": "已处理"
                                    },
                                    "type": "default",
                                    "width": "default",
                                    "behaviors": [
                                        {
                                            "type": "callback",
                                            "value": {
                                                "action": "processed"
                                            }
                                        }
                                    ],
                                    "margin": "4px 0px 4px 0px",
                                    "element_id": "dhvLe10pAJiKIIXLg8xy"
                                }
                            ],
                            "vertical_spacing": "8px",
                            "horizontal_align": "left",
                            "vertical_align": "top"
                        }
                    ],
                    "margin": "0px 0px 0px 0px"
                }
            ]
        }
    }
    
    return card


def send_to_feishu(card):
    """发送卡片到飞书"""
    payload = {"msg_type": "interactive", "card": card}
    headers = {"Content-Type": "application/json; charset=utf-8"}
    
    try:
        resp = requests.post(FEISHU_WEBHOOK_URL, headers=headers, json=payload, timeout=10)
        result = resp.json()
        if result.get("code") == 0:
            logger.info("✅ 飞书消息发送成功")
            return True, result
        else:
            logger.error(f"❌ 飞书返回错误: {result}")
            return False, result
    except Exception as e:
        logger.error(f"❌ 发送失败: {str(e)}")
        return False, {"error": str(e)}


# ================== HTTP 接口 ==================

@app.route('/webhook/alertmanager', methods=['POST'])
def alertmanager_webhook():
    """
    Alertmanager Webhook 接收端点
    """
    try:
        # 获取 Alertmanager 发送的告警数据
        alert_data = request.get_json()
        logger.info(f"收到 Alertmanager 告警: {json.dumps(alert_data, ensure_ascii=False)[:500]}")
        
        if not alert_data:
            return jsonify({"status": "error", "message": "Empty request body"}), 400
        
        # 构建飞书卡片
        card = build_alert_card(alert_data)
        
        if not card:
            return jsonify({"status": "error", "message": "No alerts found"}), 400
        
        # 发送到飞书
        success, result = send_to_feishu(card)
        
        if success:
            return jsonify({"status": "success", "message": "Alert sent to Feishu"}), 200
        else:
            return jsonify({"status": "error", "message": "Failed to send to Feishu", "detail": result}), 500
            
    except Exception as e:
        logger.error(f"处理告警失败: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """健康检查接口"""
    return jsonify({"status": "ok"}), 200


# ================== 启动服务 ==================

if __name__ == '__main__':
    logger.info("飞书告警网关启动中...")
    logger.info(f"飞书 Webhook: {FEISHU_WEBHOOK_URL}")
    logger.info("告警接收端点: http://0.0.0.0:9009/webhook/alertmanager")
    logger.info("健康检查: http://0.0.0.0:9009/health")
    
    # 启动 Flask 服务
    app.run(host='0.0.0.0', port=9009, debug=False)
