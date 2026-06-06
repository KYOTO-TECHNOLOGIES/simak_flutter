import React, { useEffect, useRef } from 'react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { X } from 'lucide-react';

interface ScannerModalProps {
    isOpen: boolean;
    onClose: () => void;
    onScan: (data: string) => void;
}

const ScannerModal: React.FC<ScannerModalProps> = ({ isOpen, onClose, onScan }) => {
    const scannerRef = useRef<Html5QrcodeScanner | null>(null);

    useEffect(() => {
        if (!isOpen) return;

        // Small timeout to ensure DOM element exists
        const timer = setTimeout(() => {
            // Prevent multiple initializations based on strict mode
            if (scannerRef.current) {
                scannerRef.current.clear().catch(() => { });
            }

            const scanner = new Html5QrcodeScanner(
                "reader",
                { fps: 10, qrbox: { width: 250, height: 250 } },
        /* verbose= */ false
            );
            scannerRef.current = scanner;

            scanner.render(
                (decodedText) => {
                    onScan(decodedText);
                    // We don't automatically close here to allow continuous scanning if needed, 
                    // but for this specific UX (modal), closing is better.
                    // However, clearing scanner immediately inside callback might cause issues.
                    // Better to let parent handle logic or clean up in useEffect return.
                    onClose();
                },
                (_errorMessage) => {
                    // ignore errors, they happen every frame no QR is detected
                }
            );
        }, 100);

        return () => {
            clearTimeout(timer);
            if (scannerRef.current) {
                scannerRef.current.clear().catch(error => console.error("Failed to clear html5-qrcode scanner. ", error));
                scannerRef.current = null;
            }
        };
    }, [isOpen]);

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-md overflow-hidden relative animate-in zoom-in-95 duration-200">
                <div className="flex justify-between items-center p-4 border-b border-gray-100">
                    <h3 className="font-bold text-lg">Scan QR Code</h3>
                    <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                        <X size={20} />
                    </button>
                </div>
                <div className="p-6">
                    <div id="reader" className="w-full overflow-hidden rounded-lg border-2 border-dashed border-gray-200"></div>
                </div>
            </div>
        </div>
    );
};

export default ScannerModal;
