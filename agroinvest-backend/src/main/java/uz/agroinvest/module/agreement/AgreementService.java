package uz.agroinvest.module.agreement;

import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.properties.TextAlignment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class AgreementService {

    private final InvestmentRepository investmentRepository;

    public AgreementService(InvestmentRepository investmentRepository) {
        this.investmentRepository = investmentRepository;
    }

    @Transactional(readOnly = true)
    public byte[] generateInvestmentAgreementPdf(UUID investmentId, UUID requestingUserId, String requestingUserRole) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sarmoya topilmadi"));

        boolean isInvestor = investment.getInvestor().getId().equals(requestingUserId);
        boolean isFarmer = investment.getProject().getFarmer().getId().equals(requestingUserId);
        boolean isStaff = "ADMIN".equals(requestingUserRole) || "SUPERADMIN".equals(requestingUserRole) || "MODERATOR".equals(requestingUserRole);

        if (!isInvestor && !isFarmer && !isStaff) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu shartnomani ko'rishga ruxsatingiz yo'q");
        }

        if (investment.getContractUrl() != null && !investment.getContractUrl().isEmpty()) {
            try {
                java.net.URL url = new java.net.URL(investment.getContractUrl());
                try (java.io.InputStream in = url.openStream();
                     ByteArrayOutputStream downloadOut = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[4096];
                    int n;
                    while ((n = in.read(buffer)) != -1) {
                        downloadOut.write(buffer, 0, n);
                    }
                    return downloadOut.toByteArray();
                }
            } catch (Exception e) {
                // fallback to auto-generator if S3 download fails
            }
        }

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfWriter writer = new PdfWriter(out);
            PdfDocument pdf = new PdfDocument(writer);
            Document document = new Document(pdf);

            // Title
            Paragraph title = new Paragraph("INVESTITSIYA SHARTNOMASI (OFFERTA)")
                    .setTextAlignment(TextAlignment.CENTER)
                    .setBold()
                    .setFontSize(16);
            document.add(title);
            
            // Subtitle / Date
            String dateStr = investment.getCreatedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            Paragraph subtitle = new Paragraph("Shartnoma raqami: AI-" + investment.getId().toString().substring(0, 8).toUpperCase() + "\nSana: " + dateStr)
                    .setTextAlignment(TextAlignment.RIGHT)
                    .setFontSize(10);
            document.add(subtitle);
            document.add(new Paragraph("\n"));

            // Content
            document.add(new Paragraph("1. SHARTNOMA SHARTLARI").setBold().setFontSize(12));
            document.add(new Paragraph(
                    "Ushbu shartnoma AgroInvest platformasi orqali Investor va Fermer o'rtasidagi kelishuvni tartibga soladi. " +
                    "Investor loyihani moliyalashtirish uchun mablag' kiritadi va Fermer loyihani o'z vaqtida parvarish qilib, mahsulotni sotish va foydani taqsimlash majburiyatini oladi."
            ).setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("2. TOMONLAR MA'LUMOTLARI").setBold().setFontSize(12));
            document.add(new Paragraph("Sarmoyador: " + investment.getInvestor().getFullName() + " (Tel: " + investment.getInvestor().getPhoneNumber() + ")").setFontSize(10));
            document.add(new Paragraph("Loyiha: " + investment.getProject().getTitle() + " (Fermer: " + investment.getProject().getFarmer().getFullName() + ")").setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("3. MOLIYAVIY PARAMETRLAR").setBold().setFontSize(12));
            document.add(new Paragraph("Sarmoya miqdori: " + investment.getAmount() + " UZS").setFontSize(10));
            document.add(new Paragraph("Loyiha muddati: " + investment.getProject().getDurationDays() + " kun").setFontSize(10));
            document.add(new Paragraph("Kutilayotgan foyda: +" + investment.getProject().getExpectedReturnPct() + "%").setFontSize(10));
            document.add(new Paragraph("Investor ulushi (Loyiha umumiy daromadida): " + investment.getSharePct() + "%").setFontSize(10));
            document.add(new Paragraph("\n"));

            // Per-project negotiated terms ("kelishuv asosida"): the profit split,
            // the farmer's own-asset contribution, and who bears running expenses -
            // spelled out so the PDF matches what the investor accepted on-screen.
            document.add(new Paragraph("4. KELISHILGAN SHARTLAR").setBold().setFontSize(12));
            document.add(new Paragraph("Sof foyda taqsimoti: Investorlar jamoasi " + stripPct(investment.getProject().getInvestorSharePct())
                    + "% / Fermer " + stripPct(investment.getProject().getFarmerSharePct()) + "%").setFontSize(10));
            if (investment.getProject().getFarmerContributionValue() != null
                    && investment.getProject().getFarmerContributionValue().signum() > 0) {
                document.add(new Paragraph("Fermerning o'z hissasi (hayvon/aktiv qiymati): "
                        + investment.getProject().getFarmerContributionValue() + " UZS"
                        + (investment.getProject().getFarmerContributionVerifiedAt() != null ? " (admin tomonidan tasdiqlangan)" : "")).setFontSize(10));
            }
            if (investment.getProject().getExpensePolicy() != null) {
                document.add(new Paragraph("Joriy harajatlar siyosati: " + expensePolicyLabel(investment.getProject().getExpensePolicy())).setFontSize(10));
            }
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("5. YAKUNIY QOIDALAR").setBold().setFontSize(12));
            document.add(new Paragraph(
                    "Mablag'lar loyiha to'liq moliyalashtirilgunga qadar platforma hamyonida muzlatiladi. Agar loyiha to'liq moliyalashtirilmasa yoki " +
                    "Platforma tomonidan hali faollashtirilmasdan bekor qilinsa, barcha mablag'lar investor balansiga to'liq va komissiyasiz qaytariladi. " +
                    "Shartnoma elektron ko'rinishda tasdiqlangan va yuridik kuchga ega."
            ).setFontSize(10));
            document.add(new Paragraph("\n"));

            // Loss disclosure for the funded-and-ran-but-sold-low scenario - the
            // paragraph above only covers "never funded/cancelled early" (full
            // refund), which previously left the far more consequential case (a
            // funded, ACTIVE project whose sale price comes in low) completely
            // undisclosed in the document investors actually sign and rely on.
            document.add(new Paragraph(
                    "Agar loyiha to'liq moliyalashtirilib faollashtirilgandan so'ng yakuniy sotuv/tugatish summasi loyiha maqsad summasidan kam bo'lsa, " +
                    "investorning (va o'z hissasi bilan qatnashgan bo'lsa, fermerning) qaytarib olinadigan summasi ular kiritgan mablag'ga PROPORSIONAL " +
                    "ravishda avtomatik hisoblanadi (Platforma xizmat haqi va fermerning tasdiqlangan xarajatlari chegirilgandan keyingi qoldiq asosida). " +
                    "Bunday holatda investor o'z asosiy mablag'ining bir qismini yoki to'liqini yo'qotishi mumkin; qaytariladigan summa nolgacha tushishi " +
                    "mumkin va HECH QANDAY MINIMAL QAYTARIM KAFOLATLANMAYDI. Platformada bunday yo'qotishlarni qoplaydigan alohida zaxira fond yoki " +
                    "sug'urta mexanizmi mavjud emas."
            ).setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph(
                    "OGOHLANTIRISH: Ko'rsatilgan daromad kutilayotgan (taxminiy) ko'rsatkich bo'lib, KAFOLATLANMAGAN. " +
                    "Qishloq xo'jaligi faoliyati tabiiy va bozor risklariga ega - sarmoyaning bir qismi yoki to'liq yo'qotilishi mumkin."
            ).setBold().setFontSize(9));

            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("PDF shartnomasini yaratishda xatolik yuz berdi", e);
        }
    }

    @Transactional(readOnly = true)
    public byte[] generateInvestmentAgreementWord(UUID investmentId, UUID requestingUserId, String requestingUserRole) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sarmoya topilmadi"));

        boolean isInvestor = investment.getInvestor().getId().equals(requestingUserId);
        boolean isFarmer = investment.getProject().getFarmer().getId().equals(requestingUserId);
        boolean isStaff = "ADMIN".equals(requestingUserRole) || "SUPERADMIN".equals(requestingUserRole) || "MODERATOR".equals(requestingUserRole);

        if (!isInvestor && !isFarmer && !isStaff) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu shartnomani ko'rishga ruxsatingiz yo'q");
        }

        String dateStr = investment.getCreatedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String amountStr = investment.getAmount().toString();
        String durationStr = String.valueOf(investment.getProject().getDurationDays());
        String returnStr = investment.getProject().getExpectedReturnPct().toString();
        String shareStr = investment.getSharePct().toString();
        String investorShareStr = stripPct(investment.getProject().getInvestorSharePct());
        String farmerShareStr = stripPct(investment.getProject().getFarmerSharePct());
        
        StringBuilder doc = new StringBuilder();
        doc.append("<html><head><meta charset='utf-8'><style>body { font-family: 'Times New Roman', serif; line-height: 1.6; padding: 20px; } h1 { text-align: center; font-size: 18px; margin-bottom: 5px; } .subtitle { text-align: right; font-size: 11px; margin-bottom: 20px; } h2 { font-size: 14px; margin-top: 20px; border-bottom: 1px solid #ccc; padding-bottom: 3px; }</style></head><body>");
        doc.append("<h1>INVESTITSIYA SHARTNOMASI (OFFERTA)</h1>");
        doc.append("<div class='subtitle'>Shartnoma raqami: AI-").append(investment.getId().toString().substring(0, 8).toUpperCase()).append("<br>Sana: ").append(dateStr).append("</div>");
        
        doc.append("<h2>1. SHARTNOMA SHARTLARI</h2>");
        doc.append("<p>Ushbu shartnoma AgroInvest platformasi orqali Investor va Fermer o'rtasidagi kelishuvni tartibga soladi. Investor loyihani moliyalashtirish uchun mablag' kiritadi va Fermer loyihani o'z vaqtida parvarish qilib, mahsulotni sotish va foydani taqsimlash majburiyatini oladi.</p>");
        
        doc.append("<h2>2. TOMONLAR MA'LUMOTLARI</h2>");
        doc.append("<p><b>Sarmoyador:</b> ").append(investment.getInvestor().getFullName()).append(" (Tel: ").append(investment.getInvestor().getPhoneNumber()).append(")</p>");
        doc.append("<p><b>Loyiha:</b> ").append(investment.getProject().getTitle()).append(" (Fermer: ").append(investment.getProject().getFarmer().getFullName()).append(")</p>");
        
        doc.append("<h2>3. MOLIYAVIY PARAMETRLAR</h2>");
        doc.append("<p><b>Sarmoya miqdori:</b> ").append(amountStr).append(" UZS</p>");
        doc.append("<p><b>Loyiha muddati:</b> ").append(durationStr).append(" kun</p>");
        doc.append("<p><b>Kutilayotgan foyda:</b> +").append(returnStr).append("%</p>");
        doc.append("<p><b>Investor ulushi (Loyiha umumiy daromadida):</b> ").append(shareStr).append("%</p>");
        
        doc.append("<h2>4. KELISHILGAN SHARTLAR</h2>");
        doc.append("<p><b>Sof foyda taqsimoti:</b> Investorlar jamoasi ").append(investorShareStr).append("% / Fermer ").append(farmerShareStr).append("%</p>");
        if (investment.getProject().getFarmerContributionValue() != null && investment.getProject().getFarmerContributionValue().signum() > 0) {
            doc.append("<p><b>Fermerning o'z hissasi (hayvon/aktiv qiymati):</b> ").append(investment.getProject().getFarmerContributionValue()).append(" UZS");
            if (investment.getProject().getFarmerContributionVerifiedAt() != null) {
                doc.append(" (admin tomonidan tasdiqlangan)");
            }
            doc.append("</p>");
        }
        if (investment.getProject().getExpensePolicy() != null) {
            doc.append("<p><b>Joriy harajatlar siyosati:</b> ").append(expensePolicyLabel(investment.getProject().getExpensePolicy())).append("</p>");
        }
        
        doc.append("<h2>5. YAKUNIY QOIDALAR</h2>");
        doc.append("<p>Mablag'lar loyiha to'liq moliyalashtirilgunga qadar platforma hamyonida muzlatiladi. Agar loyiha to'liq moliyalashtirilmasa yoki Platforma tomonidan hali faollashtirilmasdan bekor qilinsa, barcha mablag'lar investor balansiga to'liq va komissiyasiz qaytariladi. Shartnoma elektron ko'rinishda tasdiqlangan va yuridik kuchga ega.</p>");
        
        doc.append("<p>Agar loyiha to'liq moliyalashtirilib faollashtirilgandan so'ng yakuniy sotuv/tugatish summasi loyiha maqsad summasidan kam bo'lsa, investorning (va o'z hissasi bilan qatnashgan bo'lsa, fermerning) qaytarib olinadigan summasi ular kiritgan mablag'ga PROPORSIONAL ravishda avtomatik hisoblanadi (Platforma xizmat haqi va fermerning tasdiqlangan xarajatlari chegirilgandan keyingi qoldiq asosida). Bunday holatda investor o'z asosiy mablag'ining bir qismini yoki to'liqini yo'qotishi mumkin; qaytariladigan summa nolgacha tushishi mumkin va HECH QANDAY MINIMAL QAYTARIM KAFOLATLANMAYDI. Platformada bunday yo'qotishlarni qoplaydigan alohida zaxira fond yoki sug'urta mexanizmi muzokaralarda mavjud emas.</p>");
        
        doc.append("<p><b>OGOHLANTIRISH:</b> Ko'rsatilgan daromad kutilayotgan (taxminiy) ko'rsatkich bo'lib, KAFOLATLANMAGAN. Qishloq xo'jaligi faoliyati tabiiy va bozor risklariga ega - sarmoyaning bir qismi yoki to'liq yo'qotilishi mumkin.</p>");
        doc.append("</body></html>");
        
        return doc.toString().getBytes(StandardCharsets.UTF_8);
    }

    private static String stripPct(java.math.BigDecimal pct) {
        return pct == null ? "-" : pct.stripTrailingZeros().toPlainString();
    }

    private static String expensePolicyLabel(uz.agroinvest.common.enums.ExpensePolicy policy) {
        return switch (policy) {
            case INVESTOR_BUDGET -> "Loyiha byudjetidan (investor mablag'i hisobidan, shaffof hisobda)";
            case FARMER_REIMBURSED -> "Fermer to'laydi, sotuvdan keyin foyda taqsimotidan OLDIN qaytariladi";
            case MIXED -> "Aralash - har bir harajat alohida belgilanadi";
        };
    }
}
