import QtQuick
import qs.config

SpringAnimation {
    spring: Config.animation.spring
    damping: Config.animation.damping
    epsilon: 0.25
}
