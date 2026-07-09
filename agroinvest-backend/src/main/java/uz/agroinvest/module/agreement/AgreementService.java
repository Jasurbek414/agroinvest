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
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class AgreementService {

    private final InvestmentRepository investmentRepository;

    public AgreementService(InvestmentRepository investmentRepository) {
        this.investmentRepository = investmentRepository;
    }

    @Transactional(readOnly = true)
    public byte[] generateInvestmentAgreementPdf(UUID investmentId, UUID requestingUserId) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sarmoya topilmadi"));

        // Ownership check: without this, any authenticated investor who guesses/enumerates
        // a UUID can download another investor's contract (full name, phone, amount).
        if (!investment.getInvestor().getId().equals(requestingUserId)) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu shartnomani ko'rishga ruxsatingiz yo'q");
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
