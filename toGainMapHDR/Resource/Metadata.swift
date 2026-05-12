//
//  Metadata.swift
//  toGainMapHDR
//
//  Created by Luyao Peng on 13/4/2026.
//
import Foundation

func defaultHDRMetadata(GainMapMax: Float,GainMapMin: Float,RGBType: Int) -> String {
    var base64:String
    switch RGBType {
    case 1: //RGB
        base64 = """
            PHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpIRFJUb25lTWFwPSJodHRwOi8vbnMuYXBwbGUuY29tL0hEUlRvbmVNYXAvMS4wLyI+CiAgICAgICAgIDxIRFJUb25lTWFwOlZlcnNpb24+MTwvSERSVG9uZU1hcDpWZXJzaW9uPgogICAgICAgICA8SERSVG9uZU1hcDpCYXNlSGVhZHJvb20+MC4wMDAwMDA8L0hEUlRvbmVNYXA6QmFzZUhlYWRyb29tPgogICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVIZWFkcm9vbT4yLjMwMDQ1MDwvSERSVG9uZU1hcDpBbHRlcm5hdGVIZWFkcm9vbT4KICAgICAgICAgPEhEUlRvbmVNYXA6Q2hhbm5lbE1ldGFkYXRhPgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxIRFJUb25lTWFwOkdhaW5NYXBNaW4+MC4wMDAwMDA8L0hEUlRvbmVNYXA6R2Fpbk1hcE1pbj4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6R2Fpbk1hcE1heD4yLjAwMDAwMDwvSERSVG9uZU1hcDpHYWluTWFwTWF4PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpHYW1tYT4xLjAwMDAwMDwvSERSVG9uZU1hcDpHYW1tYT4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6QmFzZU9mZnNldD4wLjAwMDAxMDwvSERSVG9uZU1hcDpCYXNlT2Zmc2V0PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVPZmZzZXQ+MC4wMDAwMTA8L0hEUlRvbmVNYXA6QWx0ZXJuYXRlT2Zmc2V0PgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxIRFJUb25lTWFwOkdhaW5NYXBNaW4+MC4wMDAwMDA8L0hEUlRvbmVNYXA6R2Fpbk1hcE1pbj4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6R2Fpbk1hcE1heD4yLjAwMDAwMDwvSERSVG9uZU1hcDpHYWluTWFwTWF4PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpHYW1tYT4xLjAwMDAwMDwvSERSVG9uZU1hcDpHYW1tYT4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6QmFzZU9mZnNldD4wLjAwMDAxMDwvSERSVG9uZU1hcDpCYXNlT2Zmc2V0PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVPZmZzZXQ+MC4wMDAwMTA8L0hEUlRvbmVNYXA6QWx0ZXJuYXRlT2Zmc2V0PgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxIRFJUb25lTWFwOkdhaW5NYXBNaW4+MC4wMDAwMDA8L0hEUlRvbmVNYXA6R2Fpbk1hcE1pbj4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6R2Fpbk1hcE1heD4yLjAwMDAwMDwvSERSVG9uZU1hcDpHYWluTWFwTWF4PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpHYW1tYT4xLjAwMDAwMDwvSERSVG9uZU1hcDpHYW1tYT4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6QmFzZU9mZnNldD4wLjAwMDAxMDwvSERSVG9uZU1hcDpCYXNlT2Zmc2V0PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVPZmZzZXQ+MC4wMDAwMTA8L0hEUlRvbmVNYXA6QWx0ZXJuYXRlT2Zmc2V0PgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L0hEUlRvbmVNYXA6Q2hhbm5lbE1ldGFkYXRhPgogICAgICAgICA8SERSVG9uZU1hcDpCYXNlQ29sb3JJc1dvcmtpbmdDb2xvcj5UcnVlPC9IRFJUb25lTWFwOkJhc2VDb2xvcklzV29ya2luZ0NvbG9yPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K
            """
    case 2: //Mono
        base64 = """
            PHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpIRFJUb25lTWFwPSJodHRwOi8vbnMuYXBwbGUuY29tL0hEUlRvbmVNYXAvMS4wLyI+CiAgICAgICAgIDxIRFJUb25lTWFwOlZlcnNpb24+MTwvSERSVG9uZU1hcDpWZXJzaW9uPgogICAgICAgICA8SERSVG9uZU1hcDpCYXNlSGVhZHJvb20+MC4wMDAwMDA8L0hEUlRvbmVNYXA6QmFzZUhlYWRyb29tPgogICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVIZWFkcm9vbT4yLjMwMDQ1MDwvSERSVG9uZU1hcDpBbHRlcm5hdGVIZWFkcm9vbT4KICAgICAgICAgPEhEUlRvbmVNYXA6Q2hhbm5lbE1ldGFkYXRhPgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxIRFJUb25lTWFwOkdhaW5NYXBNaW4+MC4wMDAwMDA8L0hEUlRvbmVNYXA6R2Fpbk1hcE1pbj4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6R2Fpbk1hcE1heD4yLjAwMDAwMDwvSERSVG9uZU1hcDpHYWluTWFwTWF4PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpHYW1tYT4xLjAwMDAwMDwvSERSVG9uZU1hcDpHYW1tYT4KICAgICAgICAgICAgICAgICAgPEhEUlRvbmVNYXA6QmFzZU9mZnNldD4wLjAwMDAxMDwvSERSVG9uZU1hcDpCYXNlT2Zmc2V0PgogICAgICAgICAgICAgICAgICA8SERSVG9uZU1hcDpBbHRlcm5hdGVPZmZzZXQ+MC4wMDAwMTA8L0hEUlRvbmVNYXA6QWx0ZXJuYXRlT2Zmc2V0PgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L0hEUlRvbmVNYXA6Q2hhbm5lbE1ldGFkYXRhPgogICAgICAgICA8SERSVG9uZU1hcDpCYXNlQ29sb3JJc1dvcmtpbmdDb2xvcj5UcnVlPC9IRFJUb25lTWFwOkJhc2VDb2xvcklzV29ya2luZ0NvbG9yPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K
            """
    case 3: //Apple
        base64 = """
            PHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpIRFJHYWluTWFwPSJodHRwOi8vbnMuYXBwbGUuY29tL0hEUkdhaW5NYXAvMS4wLyI+CiAgICAgICAgIDxIRFJHYWluTWFwOkhEUkdhaW5NYXBWZXJzaW9uPjEzMTA3MjwvSERSR2Fpbk1hcDpIRFJHYWluTWFwVmVyc2lvbj4KICAgICAgICAgPEhEUkdhaW5NYXA6SERSR2Fpbk1hcEhlYWRyb29tPjIuMDAwMDA8L0hEUkdhaW5NYXA6SERSR2Fpbk1hcEhlYWRyb29tPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K
            """
    default:
        base64 = ""
        print("Warning: Unknown RGB type")
        exit(0)
    }
    
    let data = Data(base64Encoded: base64)!
    let xmlString = String(data: data, encoding: .utf8)
    
    let formattedValueMax = String(format: "%.6f", GainMapMax)
    let formattedValueMin = String(format: "%.6f", GainMapMin)
    
    let patternMax = #"<HDRToneMap:GainMapMax>.*?</HDRToneMap:GainMapMax>"#
    let replacementMax = "<HDRToneMap:GainMapMax>\(formattedValueMax)</HDRToneMap:GainMapMax>"
    
    let patternMin = #"<HDRToneMap:GainMapMin>.*?</HDRToneMap:GainMapMin>"#
    let replacementMin = "<HDRToneMap:GainMapMin>\(formattedValueMin)</HDRToneMap:GainMapMin>"
    
    let patternApple = #"<HDRGainMap:HDRGainMapHeadroom>.*?</HDRGainMap:HDRGainMapHeadroom>"#
    let replacementApple = "<HDRGainMap:HDRGainMapHeadroom>\(formattedValueMax)</HDRGainMap:HDRGainMapHeadroom>"
    
    var result_data:String
    result_data = xmlString!.replacingOccurrences(
            of: patternMax,
            with: replacementMax,
            options: .regularExpression
        )
    result_data = result_data.replacingOccurrences(
            of: patternMin,
            with: replacementMin,
            options: .regularExpression
        )
    
    result_data = result_data.replacingOccurrences(
            of: patternApple,
            with: replacementApple,
            options: .regularExpression
        )
    return result_data
}
