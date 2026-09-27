$ErrorActionPreference = 'Stop'

$file = 'lib/privacy_policy_localizations.dart'

$english = @'
PRIVACY POLICY FOR VERDICT

This Privacy Policy explains how VERDICT ("we," "us," or "our"), developed by Görkem Ali Cömert, collects, uses, and discloses information about you when you use our mobile application (the "App"). By accessing or using the App, you agree to this Privacy Policy. If you do not agree with our policies and practices, your choice is not to use our App.

1. Disclaimer regarding Affiliation
VERDICT is an independent third-party application and is not affiliated with, endorsed, sponsored, or administered by, Instagram, Facebook, or Meta Platforms, Inc. "Instagram" is a trademark of Meta Platforms, Inc. We utilize the Instagram platform strictly to provide analysis services based on the data available to you as a user.

2. The Information We Collect
We operate on a strict "On-Device Processing" principle. This means the core functionality of the App relies on data stored locally on your device. We do not operate a backend server to harvest or store your personal social media credentials.
A. Personal Data (Authentication): To perform follower analysis, you must log in to your Instagram account.
How it works: The App uses a secure WebView (a browser component within the app) to direct you to Instagram’s official login page.
Our Access: We DO NOT see, store, or transmit your password. Your session cookies and authentication tokens are stored strictly within the local secure storage of your device (e.g., Android SharedPreferences, iOS Keychain) to maintain your session.
Server Storage: We DO NOT upload your login credentials or your follower lists to any external server owned by us.
B. Usage and Device Information: We, and our third-party service providers (Google AdMob, Firebase), may automatically collect certain information about your device to improve app performance and serve advertisements. This may include:
Device model and manufacturer
Operating system version
Network type (WiFi/Cellular)
Advertising ID (AAID for Android / IDFA for iOS)
Crash logs and performance data

3. How We Use Your Information
We use the information collected for the following purposes:
To Provide Services: To compare your "Followers" and "Following" lists locally on your device to identify unfollowers, new followers, and fans.
To Maintain the App: To use Firebase Remote Config to manage app updates, maintenance modes, and feature toggles.
To Serve Ads: To display relevant advertisements via Google AdMob, which helps keep this App free to use.

4. Third-Party Services and Data Sharing
We do not sell your personal data. However, we use trusted third-party services that may collect information used to identify your device for advertising and analytics purposes. We advise you to review the privacy policies of these third-party service providers:
Google AdMob: Privacy Policy
Google Firebase: Privacy Policy

5. Data Retention and Deletion
Local Data: Since your follower data and session cookies are stored locally on your device, you have full control.
Deletion: You can delete all data stored by the App at any time by:
Logging out via the App settings.
Clearing the App's "Storage/Cache" in your phone settings.
Uninstalling the App. Once uninstalled, no trace of your data remains with us.

6. Security
We strive to use commercially acceptable means to protect your Personal Information. By processing data locally and using standard encryption for local storage, we minimize the risk of data breaches. However, no method of transmission over the internet is 100% secure.

7. Children’s Privacy
Our Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.

8. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted.

9. Contact Us
If you have any questions or suggestions, do not hesitate to contact us.
'@

# Keep product and brand names stable.
$src = $english
$src = $src.Replace('VERDICT', 'XQZPAPP001')
$src = $src.Replace('Instagram', 'XQZPIG002')
$src = $src.Replace('Facebook', 'XQZPFB003')
$src = $src.Replace('Meta Platforms, Inc.', 'XQZPMETA004')
$src = $src.Replace('Google AdMob', 'XQZPADMOB005')
$src = $src.Replace('Google Firebase', 'XQZPFIRE006')
$src = $src.Replace('Firebase Remote Config', 'XQZPFRC007')
$src = $src.Replace('WebView', 'XQZPWEB008')
$src = $src.Replace('Android SharedPreferences, iOS Keychain', 'XQZPLOCAL009')

function Restore-Placeholders([string]$text) {
  $out = $text
  $out = $out.Replace('XQZPAPP001', 'VERDICT')
  $out = $out.Replace('XQZPIG002', 'Instagram')
  $out = $out.Replace('XQZPFB003', 'Facebook')
  $out = $out.Replace('XQZPMETA004', 'Meta Platforms, Inc.')
  $out = $out.Replace('XQZPADMOB005', 'Google AdMob')
  $out = $out.Replace('XQZPFIRE006', 'Google Firebase')
  $out = $out.Replace('XQZPFRC007', 'Firebase Remote Config')
  $out = $out.Replace('XQZPWEB008', 'WebView')
  $out = $out.Replace('XQZPLOCAL009', 'Android SharedPreferences, iOS Keychain')
  return $out
}

function Translate-Segment([string]$segment, [string]$target) {
  if ([string]::IsNullOrWhiteSpace($segment)) { return $segment }
  $q = [uri]::EscapeDataString($segment)
  $url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$target&dt=t&q=$q"
  for ($i = 0; $i -lt 3; $i++) {
    try {
      $res = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
      if ($null -eq $res -or $null -eq $res[0]) { throw 'empty response' }
      $parts = @()
      foreach ($item in $res[0]) {
        if ($null -ne $item -and $item.Count -gt 0) {
          $parts += [string]$item[0]
        }
      }
      $joined = ($parts -join '')
      if (-not [string]::IsNullOrWhiteSpace($joined)) {
        return $joined
      }
      throw 'empty translated text'
    } catch {
      Start-Sleep -Milliseconds (300 + (300 * $i))
      if ($i -eq 2) { return $segment }
    }
  }
  return $segment
}

$langToApi = [ordered]@{
  'tr' = 'tr'
  'en' = 'en'
  'de' = 'de'
  'ko' = 'ko'
  'ja' = 'ja'
  'ru' = 'ru'
  'pt' = 'pt'
  'ar' = 'ar'
  'es' = 'es'
  'es-mx' = 'es'
  'hi' = 'hi'
  'hu' = 'hu'
  'zh-hans' = 'zh-CN'
  'id' = 'id'
  'nl' = 'nl'
  'fr' = 'fr'
  'it' = 'it'
  'vi' = 'vi'
  'th' = 'th'
  'pl' = 'pl'
}

# Translate in paragraph blocks to preserve structure and keep requests stable.
$blocks = $src -split "`r?`n`r?`n"

$policyByLang = [ordered]@{}
foreach ($code in $langToApi.Keys) {
  if ($code -eq 'en') {
    $policyByLang[$code] = Restore-Placeholders $src
    continue
  }

  $translatedBlocks = @()
  foreach ($block in $blocks) {
    $translated = Translate-Segment -segment $block -target $langToApi[$code]
    $translatedBlocks += $translated
  }
  $joined = ($translatedBlocks -join "`n`n")
  $policyByLang[$code] = Restore-Placeholders $joined
}

if (-not $policyByLang.Contains('es-mx')) {
  $policyByLang['es-mx'] = $policyByLang['es']
}

$orderedCodes = @('tr','en','de','ko','ja','ru','pt','ar','es','es-mx','hi','hu','zh-hans','id','nl','fr','it','vi','th','pl')

$mapBuilder = New-Object System.Text.StringBuilder
[void]$mapBuilder.AppendLine("const Map<String, String> _privacyPolicyBodies = {")
foreach ($code in $orderedCodes) {
  $txt = [string]$policyByLang[$code]
  $txt = $txt.Replace("'''", "''\\''")
  [void]$mapBuilder.AppendLine("  '$code': '''$txt''',")
}
[void]$mapBuilder.Append("};")
$newMap = $mapBuilder.ToString()

$content = Get-Content -Raw -Path $file
$pattern = 'const Map<String, String> _privacyPolicyBodies = \{[\s\S]*?\n\};'
$updated = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newMap }, 1)
if ($updated -eq $content) {
  throw 'Could not replace _privacyPolicyBodies map.'
}
Set-Content -Path $file -Value $updated -Encoding UTF8
Write-Output 'privacy bodies regenerated'
